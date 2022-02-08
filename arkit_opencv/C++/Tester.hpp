//
//  Tester.hpp
//  arkit_opencv
//
//  Created by Donghan Kim on 2022/02/08.
//

#ifndef Tester_hpp
#define Tester_hpp

#include <opencv2/opencv.hpp>
#include <stdio.h>
#include <string>


class TesterClass {
    
public:
    std::string printHello(void);
};

class Camera {
public:
    cv::Mat getOrbImg(cv::Mat img);
};


#endif /* Tester_hpp */
