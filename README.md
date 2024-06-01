# mas
This script reads URLs from standard input and issues HTTP requests to them. It supports various options to control the behavior of the requests and how the responses are handled.

# Installation
```
https://github.com/XJOKZVO/mas
```

# Options:
```
  _ __ ___     __ _   ___ 
 | '_ ` _ \   / _` | / __|
 | | | | | | | (_| | \__ \
 |_| |_| |_|  \__,_| |___/
 
Usage:
    mas.pl [options]

     Options:
       -b, --body <data>         Request body
       -d, --delay <delay>       Delay between issuing requests (ms)
       -H, --header <header>     Add a header to the request (can be specified multiple times)
           --ignore-html         Don't save HTML files; useful when looking non-HTML files only
           --ignore-empty        Don't save empty files
       -k, --keep-alive          Use HTTP Keep-Alive
       -m, --method              HTTP method to use (default: GET, or POST if body is specified)
       -M, --match <string>      Save responses that include <string> in the body
       -o, --output <dir>        Directory to save responses in (will be created)
       -s, --save-status <code>  Save responses with given status code (can be specified multiple times)
       -S, --save                Save all responses
       -x, --proxy <proxyURL>    Use the provided HTTP proxy
       -h, --help                Show this help message

Options:
    -b, --body <data>
        Request body.

    -d, --delay <delay>
        Delay between issuing requests in milliseconds.

    -H, --header <header>
        Add a header to the request. This option can be specified multiple
        times.

    --ignore-html
        Don't save HTML files; useful when looking for non-HTML files only.

    --ignore-empty
        Don't save empty files.

    -k, --keep-alive
        Use HTTP Keep-Alive.
```
