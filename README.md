bing-image-dl
=========================

A script to download images to bing.

**URGENT**: Do not make this repo public. The source code contains a private API key.

Usage
-----

Make sure you have torch installed `which th`

You'll also need to install dependencies:

    $ luarocks install luasocket
    $ luarocks install moses
    $ luarocks install graphicsmagick

Then call it from the command line with torch.
In the following example we search for images of "ratajkowski" and limit the number of downloads to 12 images.

    $ cd bing-image-dl
    $ ./init.lua -q ratajkowski -n 12

Call the script with no arguments to view more usage information.

