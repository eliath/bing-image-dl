# bing-image-dl

A script to programmatically download  large sets of images from bing.

This script is useful to amass datasets for various image processing tasks.


## Prerequisites

The script runs on [torch7](http://torch.ch/). Make sure you have it installed.

Additional lua packages are required:

    $ luarocks install async
    $ luarocks install luasocket
    $ luarocks install moses
    $ luarocks install graphicsmagick


## Usage

### Azure Setup

First you will need to get API credentials to use the _Bing Image Search API_.
Follow the steps below to obtain a key from the Azure platform.

  1. Set up a free [Microsoft Azure account](https://azure.microsoft.com/en-us/free/)
  2. Go to the [Azure portal](https://portal.azure.com/) and choose "Create A Resource"
  3. Search and select "Bing Search v7", then click "Create"
  4. Give the resource a name and choose a pricing tier.
    - The free tier is fine but rate-limited to 3 calls per second
    - Create a new resource group if necessary
  5. Next, in the sidebar, go to "All Resources" and click the name
     of the resource you just created
  6. Choose "keys" in the middle column and copy one of the API keys listed
  7. Paste your API key in `credentials.lua`.

### Getting Images

Once you have your credentials set up, use `th` to run the script
from the command line:

    th init.lua -q ratajkowski -n 12

These parameters will crawl bing for images matching the query "ratajkowski" and
limit the number of results to 12.

The results will be saved in a folder with the same name as the query.

### Options

Call the script with no arguments to view more usage information:

    th init.lua

## Troubleshooting

**Error Code 403**: you have exceeded your monthly quota. You will need
to upgrade your pricing tier by going into the Azure Portal.

**Error Code 429**: you are exceeding you calls per second limit.
Wait a while and try again.

A full list of error codes can be found [here](https://docs.microsoft.com/en-us/rest/api/cognitiveservices/bing-images-api-v7-reference#error-codes).

If you still have problems, please [open an issue](https://github.com/discretenewyork/bing-image-dl/issues/new).


## Developing

We currently use Bing image search API v7
([documentation here](https://docs.microsoft.com/en-us/rest/api/cognitiveservices/bing-images-api-v7-reference)).
