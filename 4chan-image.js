// ==UserScript==
//@name              4chan image enhancer
//@version           0.5
//@author            Frebith
//@description       Adds image enhancements to 4chan
//@license           MIT; http://www.opensource.org/licenses/mit-license.php
//@include           http*://boards.4chan.org/*
//@updateURL         https://raw.github.com/Frebith/4chanimage/master/4chan-image.js
// ==/UserScript==

/*
*Copyright (c) 2012 Frebith
*Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
*and associated documentation files (the 'Software'), to deal in the Software without restriction, 
*including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
*and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions: 
*
*The above copyright notice and this permission notice shall be included in all copies or substantial 
*portions of the Software. 
*
*THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
*LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN 
*NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
*WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
*SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/var IMAGEHOVER = true;
var IMAGEGIF = false;
var IMAGEPRELOAD = false;
var IMAGESAUCE = true;
var IMAGESAUCES = ['http://iqdb.org/?url=$1', 'http://google.com/searchbyimage?image_url=$1', '#http://tineye.com/search?url=$1', '#http://saucenao.com/search.php?db=999&url=$1', '#http://3d.iqdb.org/?url=$1', '#http://regex.info/exif.cgi?imgurl=$2', 'http://imgur.com/upload?url=$2', '#http://omploader.org/upload?url1=$2', '#http://archive.foolz.us/$4/image/$3/', '#http://archive.installgentoo.net/$4/image/$3'];
var UPDATETIME = 5000;
var IMAGEXOFFSET = 30;
var IMAGEBORDER = 0;
var imgCell = document.createElement('TD');
var imgTab = document.createElement('DIV');
imgTab.setAttribute('style', 'display:none;position:absolute;');
imgTab.appendChild(document.createElement('TABLE').appendChild(document.createElement('TR').appendChild(imgCell)));
document.body.appendChild(imgTab);
var oldImages = new Array();
var update = setTimeout(updateImages, UPDATETIME);
updateImages();
function updateImages() {
    var images = document.getElementsByClassName('fileThumb');
    for (var i = 0; i < images.length; i += 1) {
        if (oldImages.indexOf(images[i].getAttribute('href')) === -1) {
            updateImage(images[i], images[i].firstChild);
            oldImages.push(images[i].getAttribute('href'));
        };
    };
    update = setTimeout(updateImages, UPDATETIME);
    return true;
};
function updateImage(a, img) {
    if (IMAGESAUCE) {
        setupSauce(a.parentElement.firstChild, a, img);
    };
    if (IMAGEHOVER) {
        img.addEventListener('mouseover', function (x) {
            return imageShow(x, this);
        }, false);
        img.addEventListener('mousemove', function (x) {
            return imageTrack(x);
        }, true);
        img.addEventListener('mouseout', function () {
            return imageHide();
        }, false);
    };
    if (IMAGEGIF && a.getAttribute('href').indexOf('.gif') === a.getAttribute('href').length - 4) {
        img.setAttribute('src', img.parentElement.getAttribute('href'));
    };
    if (IMAGEPRELOAD) {
        img.setAttribute('src', a.getAttribute('href'));
    };
    return true;
};
function imageShow(event, img) {
    imgCell.innerHTML = '<img src="' + img.parentElement.getAttribute('href') + '" border="' + IMAGEBORDER + '">';
    imageTrack(event);
    return true;
};
function imageTrack(event) {
    if (imgCell.innerHTML) {
        var tipHeight = imgTab.clientHeight / 2;
        var vpHeight = Math.min(document.documentElement.clientHeight, document.body.clientHeight);
        var vpWidth = Math.min(document.documentElement.clientWidth, document.body.clientWidth);
        var vpBottom = window.scrollY + vpHeight;
        var tipYOffset = 0;
        imgTab.style.display = '';
        if (event.pageY - tipHeight < window.scrollY || imgTab.clientHeight > vpHeight) {
            tipYOffset = window.scrollY;
        } else if (event.pageY + tipHeight >= vpBottom) {
            tipYOffset = vpBottom - imgTab.clientHeight;
        } else {
            tipYOffset = event.pageY - tipHeight;
        };
        imgTab.style.top = tipYOffset + 'px';
        if (event.pageX > vpWidth * 0.6) {
            imgTab.style.right = ((vpWidth + IMAGEXOFFSET) - event.pageX) + 'px';
            imgTab.style.left = '';
        } else {
            imgTab.style.left = event.pageX + IMAGEXOFFSET + 'px';
            imgTab.style.right = '';
        };
    };
    return true;
};
function imageHide() {
    imgTab.style.display = 'none';
    imgCell.innerHTML = '';
    return true;
};
function setupSauce(bar, a, img) {
    var fullUrl = a.getAttribute('href');
    var thumbUrl = img.getAttribute('src');
    var md5 = img.getAttribute('data-md5');
    var board = fullUrl.match(/[/][a-zA-Z0-9]{1,}[/]/i)[0];
    var sitename = '';
    board = board.substring(1, board.length - 1);
    for (var url = null, _js_idx6 = 0; _js_idx6 < IMAGESAUCES.length; _js_idx6 += 1) {
        url = IMAGESAUCES[_js_idx6];
        if (url.charAt(0) !== '#') {
            sitename = url.match(/[a-zA-Z0-9]{1,}[.][cinou][enors]/i)[0];
            sitename = sitename.substring(0, sitename.length - 3);
            url = url.replace('$1', 'https:' + thumbUrl).replace('$2', 'https:' + fullUrl).replace('$3', md5).replace('$4', board);
            bar.innerHTML = bar.innerHTML + ' <a target="_blank" href="' + url + '">[' + sitename + ']</a>';
        };
    };
};
