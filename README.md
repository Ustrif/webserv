*This project has been created as part of the 42 curriculum by bkiskac, raydogmu.*

# Webserv

## Description

Webserv is an HTTP server written in **C++98**. It handles socket
connections, parses HTTP requests, creates responses, and manages clients
using non-blocking I/O and `epoll`.

The server currently supports:

* GET, POST and DELETE methods
* Static file serving and index files
* File uploads
* Python and Perl CGI execution
* HTTP redirects
* Custom error pages
* Directory autoindex
* Multiple ports and name-based virtual hosts

## Requirements

Webserv uses Linux networking APIs such as `epoll`, so it must be compiled and
run on Linux. The following tools are useful:

* `c++`
* `make`
* `curl`
* `python3` and `perl` for CGI
* `valgrind` for optional memory checks

## Build

```bash
git clone https://github.com/batuhankiskac/webserv.git
cd webserv
make
```

The project is compiled with:

```text
-Wall -Wextra -Werror -std=c++98
```

Other Makefile commands:

```bash
make clean   # Remove object files
make fclean  # Remove object files and the executable
make re      # Clean and rebuild
```

## Run

From the repository root, start the server with the default configuration:

```bash
./webserv config/default.conf
```

The general syntax is:

```bash
./webserv [configuration_file]
```

If no configuration file is provided, the server uses its built-in default
configuration. The configuration file path is resolved from the current
working directory, so run the command from the repository root.

## Default configuration

[`config/default.conf`](config/default.conf) defines three virtual servers:

| Listener | Server name(s) | Content |
| --- | --- | --- |
| `127.0.0.1:8080` | `webserv.local`, `www.webserv.local` | Main demo server |
| `127.0.0.1:8080` | `api.webserv.local`, `api.local` | Read-only name-based host |
| `127.0.0.1:9090` | `secondary.webserv.local` | Secondary static site |

The main server contains the following locations:

| Location | Methods | Behavior |
| --- | --- | --- |
| `/` | GET, POST | Serves `./website`; indexes are `index.html` and `default.html` |
| `/autoindex` | GET | Serves `./website/autoindex` with directory listing enabled |
| `/deeper` | DELETE | Deletes files from `./website/deeper` |
| `/upload` | GET, POST | Stores request bodies in `./post_body`; limit is 1 MiB |
| `/cgi-py` | GET, POST | Runs `.py` files with `/usr/bin/python3` |
| `/cgi-pl` | GET, POST | Runs `.pl` files with `/usr/bin/perl` |
| `/redirect-301` | GET | Redirects to `/` with HTTP 301 |

The main server has a 10 MiB request-body limit. The API and secondary hosts
have limits of 4 MiB and 1 MiB respectively. The main and secondary servers
listen only on `127.0.0.1`; they are not exposed on other interfaces.

For a location, the configured `root` replaces the location prefix. For
example, `/autoindex/file1.txt` maps to
`./website/autoindex/file1.txt`, and `/deeper/deleteme.txt` maps to
`./website/deeper/deleteme.txt`.

## `curl` examples

Start the server first:

```bash
./webserv config/default.conf
```

### Static files and autoindex

```bash
# Main site (serves website/default.html)
curl -i http://127.0.0.1:8080/

# A static file
curl -i http://127.0.0.1:8080/autoindex/file1.txt

# Directory listing
curl -i http://127.0.0.1:8080/autoindex/
```

### Virtual hosts

Use `--resolve` to send the configured host name while connecting to
localhost:

```bash
# Name-based host on port 8080
curl --resolve api.webserv.local:8080:127.0.0.1 \
     -i http://api.webserv.local:8080/

# The separate listener on port 9090
curl --resolve secondary.webserv.local:9090:127.0.0.1 \
     -i http://secondary.webserv.local:9090/
```

### POST and uploads

The upload handler stores the complete request body under `post_body/` with an
automatically generated `.dat` filename:

```bash
# Upload a text file as the raw request body
curl -i --data-binary @website/autoindex/file1.txt \
     http://127.0.0.1:8080/upload

# Send form data to the Python CGI
curl -i -X POST \
     -d 'name=webserv&message=hello' \
     'http://127.0.0.1:8080/cgi-py/cgi.py?source=curl'
```

### CGI

The CGI scripts display request information, query parameters, headers, and
the request body:

```bash
curl -i 'http://127.0.0.1:8080/cgi-py/cgi.py?name=python'
curl -i 'http://127.0.0.1:8080/cgi-pl/cgi.pl?name=perl'
```

### DELETE and redirects

The following command deletes the sample file from `website/deeper/`:

```bash
curl -i -X DELETE http://127.0.0.1:8080/deeper/deleteme.txt
```

The redirect location can be inspected with `-i`:

```bash
curl -i http://127.0.0.1:8080/redirect-301
```

## Resources

* [RFC 9110 - HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110)
* [RFC 9112 - HTTP/1.1](https://www.rfc-editor.org/rfc/rfc9112)
* [MDN HTTP Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP)
* [NGINX Documentation](https://nginx.org/en/docs/)
* [Linux epoll Documentation](https://man7.org/linux/man-pages/man7/epoll.7.html)
* https://www.youtube.com/watch?v=L0jMBrCEQNQ&t=29s
* https://www.youtube.com/watch?v=hWyBeEF3CqQ
* https://www.youtube.com/watch?v=WuwUk7Mk80E&t=88s

### AI Usage

We used AI mainly as a support tool during development. It helped us with:

* understanding HTTP and networking concepts
* thinking about possible edge cases
* organizing the documentation
* creating test scripts for debugging
