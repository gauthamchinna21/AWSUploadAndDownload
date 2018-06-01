//
//  AWSUpload.m
//  AWSAudioUpload
//
//  Created by Mac-OBS-5 on 25/05/18.
//  Copyright © 2018 Mac-OBS-5. All rights reserved.
//

#import "AWSUpload.h"


#import <AWSS3/AWSS3TransferManager.h>
@import AWSS3;

@implementation AWSUpload


#pragma mark Image Upload to AWS3

-(void)uploadImageToAWS:(UIImage *)image withFileName:(NSString *)fileEndPoint withBucket:(NSString *)bucketName withImageFormat:(NSString *)imageFormatType withcompletion:(void (^)(id results)) completion {
    
   
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", imageFormatType]];
    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
    NSString *randomFileName = [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingString:imageFormatType];
    NSString *tempFileName =[NSString stringWithFormat:@"%@/avatar/%@",fileEndPoint,randomFileName];//userid/broadcasts/images/filename
    NSData * imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:filePath atomically:YES];
    
    AWSS3GetPreSignedURLRequest *getPreSignedURLRequest = [AWSS3GetPreSignedURLRequest new];
    getPreSignedURLRequest.bucket = bucketName;
    getPreSignedURLRequest.key = tempFileName;
    getPreSignedURLRequest.HTTPMethod = AWSHTTPMethodPUT;
    getPreSignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:3600];
    if ([imageFormatType isEqualToString:@".png"]){
        
        getPreSignedURLRequest.contentType = @"image/png";
        
        [self upload:getPreSignedURLRequest filename:tempFileName fileUploadUrl:[NSURL fileURLWithPath:filePath] contentSet:@"image/png" withcompletion:^(id results) {
            if (results != nil) {
                completion(results);
            }
            else {
                completion(nil);
            }
        }];
    }else if ([imageFormatType isEqualToString:@".jpeg"]){
        
        getPreSignedURLRequest.contentType = @"image/jpeg";
       
        [self upload:getPreSignedURLRequest filename:tempFileName fileUploadUrl:[NSURL fileURLWithPath:filePath] contentSet:@"image/jpeg" withcompletion:^(id results) {
            if (results != nil) {
                completion(results);
            }
            else {
                completion(nil);
            }
        }];
    }
    else{
        
        getPreSignedURLRequest.contentType = @"image/gif";
        
        [self upload:getPreSignedURLRequest filename:tempFileName fileUploadUrl:[NSURL fileURLWithPath:filePath] contentSet:@"image/gif" withcompletion:^(id results) {
            if (results != nil) {
                completion(results);
            }
            else {
                completion(nil);
            }
        }];
    }
}

-(void)upload:(AWSS3GetPreSignedURLRequest *)uploadRequest filename:(NSString *)tempName fileUploadUrl:(NSURL *)tempFileUrl contentSet:(NSString *)tempContent withcompletion:(void (^)(id results))completion {
    [[[AWSS3PreSignedURLBuilder defaultS3PreSignedURLBuilder] getPreSignedURL:uploadRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"Error: %@",task.error);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil);
            });
        }else {
            NSURL *presignedURL = task.result;
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
            [request setHTTPMethod:@"PUT"];
            [request setValue:[NSString stringWithFormat:@"%@",tempContent] forHTTPHeaderField:@"Content-Type"];
            NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate:self delegateQueue: [NSOperationQueue mainQueue]];
            
            [[delegateFreeSession uploadTaskWithRequest:request fromFile:tempFileUrl
                                      completionHandler:^(NSData *data, NSURLResponse *response,NSError *error) {
                                          NSLog(@"Response: %@", response);
                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                          NSLog(@"response status code: %ld", (long)[httpResponse statusCode]);
                                          if([httpResponse statusCode] == 200){
                                              //Call the service Call
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  completion(tempName);
                                              });
                                              
                                          }else{
                                              NSLog(@"Error: %@", error);
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  completion(nil);
                                              });
                                          }
                                      }] resume];
        }
        return nil;
    }];
    
}



#pragma mark upload Audio AWS3
-(void)uploadVideoToAWS:(NSData *)videoUrl withFileName:(NSString *)fileEndPoint withBucket:(NSString *)bucketName withcompletion:(void (^)(id results)) uploadCompletion {
    NSString *videoName = [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingString:@".mp4"];
    NSString *tempFileSize = @"300x250";
    NSURL* uploadURL = [NSURL fileURLWithPath:
                        [NSTemporaryDirectory() stringByAppendingPathComponent:videoName]];
    [self compressVideo:videoUrl outputURL:uploadURL handler:^(AVAssetExportSession *completion) {
        if (completion.status == AVAssetExportSessionStatusCompleted){
            NSString *fileName = [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingString:@".mp4"]; //@"mov"
            NSString *tempFileName =[NSString stringWithFormat:@"%@/%@",fileEndPoint,fileName];
            AWSS3GetPreSignedURLRequest *getPreSignedURLRequest = [AWSS3GetPreSignedURLRequest new];
            getPreSignedURLRequest.bucket = bucketName; //musation-dev-videos
            getPreSignedURLRequest.key = tempFileName;
            getPreSignedURLRequest.HTTPMethod = AWSHTTPMethodPUT;
            getPreSignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:3600];
            //Call AWS   //movie/mov
            [self videoUploadProcess:getPreSignedURLRequest videoFileUrl:uploadURL contentSet:@"video/mp4" withFileName:tempFileName withFileSize:tempFileSize withcompletion:^(id results) {//@""
                if (results != nil) {
                    uploadCompletion(tempFileName);
                }
                else {
                    uploadCompletion(nil);
                }
            }];
        }else if (completion.status == AVAssetExportSessionStatusCancelled){
            NSLog(@"Compression Export Canceled");
            uploadCompletion(nil);
        }else{
            NSLog(@"Compression Failed");
            uploadCompletion(nil);
        }
        
    }];
}



-(void)videoUploadProcess:(AWSS3GetPreSignedURLRequest *)uploadRequest videoFileUrl:(NSURL *)tempFileUrl contentSet:(NSString *)tempContent withFileName:(NSString *)fileName withFileSize:(NSString *)fileSize withcompletion:(void (^)(id results)) completion {
    [[[AWSS3PreSignedURLBuilder defaultS3PreSignedURLBuilder] getPreSignedURL:uploadRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"Error: %@",task.error);
            completion(nil);
        }else{
            NSURL *presignedURL = task.result;
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
            [request setHTTPMethod:@"PUT"];
            [request setValue:[NSString stringWithFormat:@"%@",tempContent] forHTTPHeaderField:@"Content-Type"];
            [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
            
            NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *urlSession = [NSURLSession sessionWithConfiguration: sessionConfiguration delegate:self delegateQueue: [NSOperationQueue mainQueue]];
            [[urlSession uploadTaskWithRequest:request fromFile:tempFileUrl
                             completionHandler:^(NSData *data, NSURLResponse *response,NSError *error) {
                                 NSLog(@"Response: %@", response);
                                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                 //  dispatch_sync(dispatch_get_main_queue(), ^{
                                 if([httpResponse statusCode] == 200){
                                     //Make Service Call
                                     completion(tempFileUrl);
                                 }else{
                                     NSLog(@"Error: %@", error);
                                     completion(nil);
                                 }
                                 // });
                                 
                             }]resume];
        }
        return nil;
    }];
}

- (void)compressVideo:(NSURL*)inputURL outputURL:(NSURL*)outputURL handler:(void (^)(AVAssetExportSession*))completion {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:urlAsset presetName:AVAssetExportPresetHighestQuality];
        exportSession.outputURL = outputURL;
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        exportSession.shouldOptimizeForNetworkUse = YES;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            completion(exportSession);
        }];
    });
}



- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    NSLog(@"Sent %lld of %lld bytes ----->>>>> ", totalBytesSent, totalBytesExpectedToSend);
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //      //  NSNumber *progress = [NSNumber numberWithFloat:(totalBytesSent / totalBytesSent)];
    //        float myProgress = (float)totalBytesSent / (float)totalBytesExpectedToSend;
    //        NSLog(@"Proggy: %.2f",(float)myProgress);
    //        [KVNProgress showProgress:myProgress status:NSLocalizedString(@"Uploading",@"")];
    //    });
    if (self.delegate != nil) {
        float myProgress = (float)totalBytesSent / (float)totalBytesExpectedToSend;
        [self.delegate didReceiveUploadingProgress:myProgress];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"S3 UploadTask: %@ completed with error: %@", task, [error localizedDescription]);
    }else {
        NSLog(@"S3 UploadTask: %@ completed @", task);
        //        dispatch_async(dispatch_get_main_queue(), ^{
        //            [KVNProgress showProgress:1.0 status:NSLocalizedString(@"Done",@"")];
        //        });
        
    }
    if (self.delegate != nil) {
        [self.delegate didCompleteDownloading:task didCompleteWithError:error];
    }
}



-(void)uploadAudioToAWS:(NSData *)audioFile withFileName:(NSString *)fileEndPoint withBucket:(NSString *)bucketName withcompletion:(void (^)(id results)) uploadCompletion {
    NSString *videoName = [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingString:@".m4a"];
    NSString *tempFileSize = @"300x250";
    NSURL* uploadURL = [NSURL fileURLWithPath:
                        [NSTemporaryDirectory() stringByAppendingPathComponent:videoName]];
    
    NSString *fileName = [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingString:@".mp4"];
    NSString *tempFileName =[NSString stringWithFormat:@"%@/%@",fileEndPoint,fileName];
    AWSS3GetPreSignedURLRequest *getPreSignedURLRequest = [AWSS3GetPreSignedURLRequest new];
    getPreSignedURLRequest.bucket = bucketName;
    getPreSignedURLRequest.key = tempFileName;
    getPreSignedURLRequest.HTTPMethod = AWSHTTPMethodPUT;
    getPreSignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:3600];
    
    //Call AWS
    [self audioUploadProcess:getPreSignedURLRequest videoFileUrl:audioFile contentSet:@"audio/mp4" withFileName:tempFileName withFileSize:tempFileSize withcompletion:^(id results) {
        if (results != nil) {
            uploadCompletion(results);
        }
        else {
            uploadCompletion(nil);
        }
    }];
    
}

-(void)audioUploadProcess:(AWSS3GetPreSignedURLRequest *)uploadRequest videoFileUrl:(NSData *)audioData contentSet:(NSString *)tempContent withFileName:(NSString *)fileName withFileSize:(NSString *)fileSize withcompletion:(void (^)(id results)) completion {
    [[[AWSS3PreSignedURLBuilder defaultS3PreSignedURLBuilder] getPreSignedURL:uploadRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"Error: %@",task.error);
            completion(nil);
        }else{
            NSURL *presignedURL = task.result;
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
            [request setHTTPMethod:@"PUT"];
            [request setValue:[NSString stringWithFormat:@"%@",tempContent] forHTTPHeaderField:@"Content-Type"];
            [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
            NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *urlSession = [NSURLSession sessionWithConfiguration: sessionConfiguration delegate:self delegateQueue: [NSOperationQueue mainQueue]];
            [[urlSession uploadTaskWithRequest:request fromData:audioData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSLog(@"Response: %@", response);
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                // dispatch_sync(dispatch_get_main_queue(), ^{
                if([httpResponse statusCode] == 200){
                    //Make Service Call
                    completion(fileName);
                }else{
                    NSLog(@"Error: %@", error);
                    completion(nil);
                }
                //});
            }]resume];
            
        }
        return nil;
    }];
    
}



@end
