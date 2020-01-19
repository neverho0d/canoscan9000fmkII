# canoscan9000fmkII
a set os scripts to scan films and slides with Canon CanoScan 9000F Mark II

I used this script on my Linux (Fedora 29 at the time when they were wrote and used) to automate
the process of scanning my archive of films where I have pretty various types of films - 35mm color and BW films,
6cm color and BW films and 35mm slides.

The scanner allows you to scan films, chopped into a chunks of various length, dividing result into a set of files,
so each of the files present one frame of the film. Similar process is used for slides.

Download or clone the scripts and run them with the name of the film strip or slides set (I found this convenient).
As a result you'll get the folder with original TIFFs and processed JPEGs. Negatives will be converted to positive.

Dependences:
- sane-backends for scanimage utility
- ImageMagic for convert utility
- Fred Weinhaus's negative2positive that you can get here http://www.fmwconcepts.com/imagemagick/negative2positive/index.php
