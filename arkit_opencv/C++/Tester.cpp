//
//  Tester.cpp
//  arkit_opencv
//
//  Created by Donghan Kim on 2022/02/08.
//

#include "Tester.hpp"

std::string TesterClass::printHello(){
    return "hello world!";
}

cv::Mat getOrbImg(cv::Mat img){
    cv::Ptr<cv::FeatureDetector> detector = cv::ORB::create();
    
    return cv::Mat(3,3, CV_32FC2);
}
