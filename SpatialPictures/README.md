# SpatialPictures
This project adds images of the environment into 3D-space when the device moves and saves the camera parameters into a file. The saved images and camera parameters could be used in structure-reconstruction with for example [COLMAP](https://demuc.de/colmap/) or [OpenSfM](https://www.opensfm.org).


## Tested on

* iPhone X with iOS 13.4 and ARKit 2.0
* iPad (5th Gen) with iOS 13.3 and ARKit 2.0


## Future improvements
* user interface and dynamic features
* the performance of the image conversion from CVPixelBuffer into JPEG could be improved (current conversion CVPixelBuffer -> CIImage -> UIImage -> JPEG)
* saving the camera parameters into a .csv-file instead of .txt-file


## License

Available as open source under the terms of the MIT License. 
