*Bu proje 42 müfredatının bir parçası olarak bkiskac ve raydogmu tarafından geliştirilmiştir.*

# Webserv

> **Not:** Bu belge yapay zekâ kullanılarak İngilizce README'den Türkçeye
> çevrilmiştir.

## Açıklama

Webserv, **C++98** ile yazılmış bir HTTP sunucusudur. Soket bağlantılarını
yönetir, HTTP isteklerini ayrıştırır, yanıtlar oluşturur ve istemcileri
bloklamayan I/O ile `epoll` kullanarak yönetir.

Sunucunun desteklediği özellikler:

* GET, POST ve DELETE metotları
* Statik dosya ve index dosyası sunumu
* Dosya yükleme
* Python ve Perl CGI çalıştırma
* HTTP yönlendirmeleri
* Özel hata sayfaları
* Dizin otomatik listeleme
* Birden fazla port ve ada göre virtual host seçimi

## Gereksinimler

Webserv, `epoll` gibi Linux ağ API'lerini kullandığı için Linux üzerinde
derlenmeli ve çalıştırılmalıdır. Aşağıdaki araçlar gereklidir veya faydalıdır:

* `c++`
* `make`
* `curl`
* CGI için `python3` ve `perl`
* İsteğe bağlı bellek kontrolleri için `valgrind`

## Derleme

```bash
git clone https://github.com/batuhankiskac/webserv.git
cd webserv
make
```

Proje şu derleme bayraklarıyla derlenir:

```text
-Wall -Wextra -Werror -std=c++98
```

Diğer Makefile komutları:

```bash
make clean   # Nesne dosyalarını siler
make fclean  # Nesne dosyalarını ve çalıştırılabilir dosyayı siler
make re      # Temizleyip yeniden derler
```

## Çalıştırma

Proje kök dizininden sunucuyu varsayılan yapılandırmayla başlatın:

```bash
./webserv config/default.conf
```

Genel kullanım biçimi:

```bash
./webserv [yapılandırma_dosyası]
```

Yapılandırma dosyası verilmezse sunucu kendi varsayılan yapılandırması olan
`config/default.conf` dosyasını kullanır. Yapılandırma dosyasının yolu mevcut
çalışma dizinine göre çözümlendiğinden komutu proje kök dizininde çalıştırın.

## Varsayılan yapılandırma

[`config/default.conf`](config/default.conf) üç virtual server tanımlar:

| Dinleyici | Server adı | İçerik |
| --- | --- | --- |
| `127.0.0.1:8080` | `webserv.local`, `www.webserv.local` | Ana demo sunucusu |
| `127.0.0.1:8080` | `api.webserv.local`, `api.local` | Salt okunur ada göre host |
| `127.0.0.1:9090` | `secondary.webserv.local` | İkincil statik site |

Ana sunucunun location tanımları:

| Location | Metotlar | Davranış |
| --- | --- | --- |
| `/` | GET, POST | `./website` dizinini sunar; index dosyaları `index.html` ve `default.html` |
| `/autoindex` | GET | `./website/autoindex` dizinini otomatik listelemeyle sunar |
| `/deeper` | DELETE | `./website/deeper` içindeki dosyaları siler |
| `/upload` | GET, POST | İstek gövdelerini `./post_body` içine kaydeder; limit 1 MiB |
| `/cgi-py` | GET, POST | `.py` dosyalarını `/usr/bin/python3` ile çalıştırır |
| `/cgi-pl` | GET, POST | `.pl` dosyalarını `/usr/bin/perl` ile çalıştırır |
| `/redirect-301` | GET | HTTP 301 ile `/` adresine yönlendirir |

Ana sunucunun istek gövdesi limiti 10 MiB'dir. API ve ikincil sunucuların
limitleri sırasıyla 4 MiB ve 1 MiB'dir. Ana ve ikincil sunucular yalnızca
`127.0.0.1` üzerinde dinler; diğer ağ arayüzlerine açık değildir.

Bir location için yapılandırılan `root`, location önekini değiştirir. Örneğin
`/autoindex/file1.txt`, `./website/autoindex/file1.txt` dosyasına; ve
`/deeper/deleteme.txt`, `./website/deeper/deleteme.txt` dosyasına karşılık
gelir.

## `curl` örnekleri

Önce sunucuyu başlatın:

```bash
./webserv config/default.conf
```

### Statik dosyalar ve autoindex

```bash
# Ana siteyi açar (website/default.html sunulur)
curl -i http://127.0.0.1:8080/

# Statik bir dosya
curl -i http://127.0.0.1:8080/autoindex/file1.txt

# Dizin listesini görüntüler
curl -i http://127.0.0.1:8080/autoindex/
```

### Virtual host'lar

`--resolve`, yapılandırılmış host adını kullanırken bağlantının localhost'a
yapılmasını sağlar:

```bash
# 8080 portundaki ada göre seçilen host
curl --resolve api.webserv.local:8080:127.0.0.1 \
     -i http://api.webserv.local:8080/

# 9090 portundaki ayrı dinleyici
curl --resolve secondary.webserv.local:9090:127.0.0.1 \
     -i http://secondary.webserv.local:9090/
```

### POST ve dosya yükleme

Upload işleyicisi isteğin tamamını `post_body/` altında, otomatik oluşturulan
`.dat` uzantılı bir dosya adıyla saklar:

```bash
# Bir metin dosyasını ham istek gövdesi olarak yükler
curl -i --data-binary @website/autoindex/file1.txt \
     http://127.0.0.1:8080/upload

# Python CGI'ye form verisi gönderir
curl -i -X POST \
     -d 'name=webserv&message=hello' \
     'http://127.0.0.1:8080/cgi-py/cgi.py?source=curl'
```

### CGI

CGI betikleri istek bilgilerini, sorgu parametrelerini, header'ları ve istek
gövdesini görüntüler:

```bash
curl -i 'http://127.0.0.1:8080/cgi-py/cgi.py?name=python'
curl -i 'http://127.0.0.1:8080/cgi-pl/cgi.pl?name=perl'
```

### DELETE ve yönlendirmeler

Aşağıdaki komut `website/deeper/` içindeki örnek dosyayı siler:

```bash
curl -i -X DELETE http://127.0.0.1:8080/deeper/deleteme.txt
```

Yönlendirme adresi `-i` seçeneğiyle görülebilir:

```bash
curl -i http://127.0.0.1:8080/redirect-301
```

## Kaynaklar

* [RFC 9110 - HTTP Semantiği](https://www.rfc-editor.org/rfc/rfc9110)
* [RFC 9112 - HTTP/1.1](https://www.rfc-editor.org/rfc/rfc9112)
* [MDN HTTP Dokümantasyonu](https://developer.mozilla.org/en-US/docs/Web/HTTP)
* [NGINX Dokümantasyonu](https://nginx.org/en/docs/)
* [Linux epoll Dokümantasyonu](https://man7.org/linux/man-pages/man7/epoll.7.html)
* https://www.youtube.com/watch?v=L0jMBrCEQNQ&t=29s
* https://www.youtube.com/watch?v=hWyBeEF3CqQ
* https://www.youtube.com/watch?v=WuwUk7Mk80E&t=88s

### Yapay zekâ kullanımı

Geliştirme sırasında yapay zekâyı çoğunlukla destek aracı olarak kullandık.
Yapay zekâ şu konularda yardımcı oldu:

* HTTP ve ağ kavramlarını anlamak
* Olası uç durumları değerlendirmek
* Dokümantasyonu düzenlemek
* Hata ayıklama için test betikleri oluşturmak
