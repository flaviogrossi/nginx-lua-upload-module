# nginx-lua-upload-module
Module for the nginx web server to handle multipart/form-data uploads (RFC 1867) with files of any size.

This module processes the incoming upload request and stores all the file in a configurable directory on the filesystem, without storing the (possibly big) data files in memory. The request is then modified to contain the on-disk path to the uploaded files and then passed to the location specified in the `backend_url` directive.

The files persist on the filesystem until the backend cleans them up or automatically deleted in case of a backend error. The returned HTTP codes which are considered to be an error are specified in the `upload_cleanup` directive.

## Installation
To use this module you will need nginx compiled with support for [lua-nginx-module](https://github.com/openresty/lua-nginx-module). This module also requires the following packages:

* [lua-posix](https://github.com/luaposix/luaposix);
* [lua-lpeg](https://luarocks.org/modules/gvvaughan/lpeg).

A sample nginx configuration is provided [here](https://github.com/flaviogrossi/nginx-lua-upload-module/blob/master/nginx.conf.sample).
