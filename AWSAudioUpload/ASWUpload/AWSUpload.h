//
//  AWSUpload.h
//  AWSAudioUpload
//
//  Created by Mac-OBS-5 on 25/05/18.
//  Copyright © 2018 Mac-OBS-5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import <MediaPlayer/MediaPlayer.h>


@protocol AWSUploadDelegate <NSObject>

@optional
-(void)didReceiveUploadingProgress:(float)prog ;
-(void)didCompleteDownloading:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error ;

@end

@interface AWSUpload : NSObject
@property (nonatomic,assign)id<AWSUploadDelegate> delegate;

-(void)uploadImageToAWS:(UIImage *)image withFileName:(NSString *)fileEndPoint withBucket:(NSString *)bucketName withImageFormat:(NSString *)imageFormatType withcompletion:(void (^)(id results)) completion;

-(void)uploadVideoToAWS:(NSData *)videoUrl withFileName:(NSString *)fileEndPoint withBucket:(NSString *)bucketName withcompletion:(void (^)(id results)) uploadCompletion;

-(void)uploadAudioToAWS:(NSData *)audioFile withFileName:(NSString *)fileEndPoint withBucket:(NSString *)bucketName withcompletion:(void (^)(id results)) uploadCompletion;

@end
