//
//  SPRemoteResource.m
//  SlidePayCore
//
//  Created by Alex Garcia on 9/23/13.
//  Copyright (c) 2013 SlidePay. All rights reserved.
//

#import "SPRemoteResource.h"


static NSString * realEndpoint = nil;
static NSString * token;
static NSString * apiKey;
static NSIndexSet * successCodes;
static NSIndexSet * failureCodes;
static RKObjectManager *sharedManager;

@implementation SPRemoteResource

@synthesize endpoint = _endpoint;

-(id) init{
    if (self = [super init]) {
        if(realEndpoint){
            _endpoint = [realEndpoint copy];
        }else{
            _endpoint = @"https://supervisor.getcube.com:65532/rest.svc/API/";
        }
        self.objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:_endpoint]];
        [self.objectManager.HTTPClient setDefaultHeader:@"Content-Type" value:@"application/json"];
        self.objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
        if(apiKey){
            NSLog(@"setting api key to %@",apiKey);
            [self.objectManager.HTTPClient setDefaultHeader:@"x-cube-api-key" value:apiKey];
        }else if(token){
            [self.objectManager.HTTPClient setDefaultHeader:@"x-cube-token" value:token];
        }
        
        _TAG = @"SP_RemoteResource";

    }
    return self;
}

+(void) reset{
    realEndpoint = nil;
    token = nil;
    [sharedManager.HTTPClient setDefaultHeader:@"x-cube-api-key" value:nil];
    [sharedManager.HTTPClient setDefaultHeader:@"x-cube-token"   value:nil];
}

-(NSString*) authToken{
    return [token copy];
}
-(NSString*) endpoint{
    return [realEndpoint copy];
}

+(void) configureWithResponse:(NSDictionary*)response;{

    NSString * endpointKey = @"endpoint";
    NSString * tokenKey = @"data";
    
    realEndpoint = [response valueForKey:endpointKey] == [NSNull null] ? nil : [response valueForKey:endpointKey];
    realEndpoint = [realEndpoint stringByAppendingString:@"/rest.svc/API/"];

    token = [response valueForKey:tokenKey] == [NSNull null] ? nil : [response valueForKey:tokenKey];
    if(token == nil || realEndpoint == nil){
        NSLog(@"WARNING *** token or enpoint were nil");
        NSLog(@"        *** token: %@",token);
        NSLog(@"        *** endpoint: %@",realEndpoint);
        NSLog(@"        *** %@ response: %@",@"SP_RemoteResource",response);
    }else{
        [sharedManager.HTTPClient setDefaultHeader:@"x-cube-token" value:token];
    }
}

+(void) setAPIKey:(NSString *)key withEnpoint:(NSString*)ep;{
    apiKey = key;
    realEndpoint = (ep && ![ep isEqualToString:@""]) ? [NSString stringWithFormat:@"https://%@.getcube.com:65532/rest.svc/API/",ep] : nil;
    [sharedManager.HTTPClient setDefaultHeader:@"x-cube-api-key" value:apiKey];
}

+(RKObjectManager*) sharedManager{ //apikeys always supercede tokens when evaluating requests on the backend
    
    if(realEndpoint && !sharedManager){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:realEndpoint]];
            [sharedManager.HTTPClient setDefaultHeader:@"Content-Type" value:@"application/json"];
            [sharedManager.HTTPClient setDefaultHeader:@"x-cube-encoding" value:@"application/json"];
            if(apiKey){
                [sharedManager.HTTPClient setDefaultHeader:@"x-cube-api-key" value:apiKey];
            }else if(token){
                [sharedManager.HTTPClient setDefaultHeader:@"x-cube-token" value:token];
            }
            sharedManager.requestSerializationMIMEType = RKMIMETypeJSON;
        });
    }
    
    return sharedManager;
    
}

+(NSIndexSet*) failureCodes{
    return RKStatusCodeIndexSetForClass(RKStatusCodeClassServerError);
}
+(NSIndexSet*) successCodes{
    return RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
}

+(NSDictionary*)responseFromOperation:(AFHTTPRequestOperation*)operation;{
    NSData *responseData = operation.responseData;
    if(responseData == nil) return nil;
    NSError *jsonError;
    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&jsonError];
     if(jsonError){NSLog(@"errorwhile parsing operation response: %@",jsonError);return nil;}
    return responseObject;
}

+(BOOL)responseSanityCheck:(NSDictionary*)response errorCode:(NSNumber**)code errorMessage:(NSString**)message;{
    NSNumber *successObj = [response valueForKey:@"success"];
    
    if(successObj == nil){
        return FALSE;
    }
    if((NSNull*)successObj == [NSNull null]){
        return FALSE;
    }
    if(successObj.boolValue == FALSE){
        NSDictionary * dataDict = [response valueForKey:@"data"];
        NSNumber * errorCode = [dataDict valueForKey:@"error_code"];
        NSString * errorMessage = [dataDict valueForKey:@"error_text"];
        if(errorCode == nil || (NSNull*)errorCode == [NSNull null] || errorMessage == nil || (NSNull*)errorMessage == [NSNull null]){
            NSLog(@"Bad error dictionary when trying to parse response with success = false: %@",response);
        }else{
            *code = errorCode;
            *message = errorMessage;
        }
        return FALSE;
    }
    
    return TRUE;
}

+(BOOL) checkResponseObjectForSuccessFlag:(id)responseObject failure:(ResourceFailureBlock)failure;{
    
    if([responseObject isKindOfClass:[NSDictionary class]]){
        NSNumber *errorCode;
        NSString *errorMessage;
        BOOL successFlag = [SPRemoteResource responseSanityCheck:responseObject errorCode:&errorCode errorMessage:&errorMessage];
        if(successFlag == FALSE){
            if(errorCode && errorMessage){
                failure(errorCode.integerValue,errorMessage,nil);
            }else{
                failure(0,nil,[NSError errorWithDomain:@"Login Request" code:WRONG_OBJECT userInfo:@{NSLocalizedDescriptionKey:@"Success flag is false"}]);
            }
        }else{
            return TRUE;
        }
    }else{
        failure(0,nil,[NSError errorWithDomain:@"Login Request" code:SUCCESS_FLAG_FALSE userInfo:@{NSLocalizedDescriptionKey:@"The object returned by the request was not a dictionary."}]);
    }
    return FALSE;
    
}


@end