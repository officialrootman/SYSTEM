#import <Foundation/Foundation.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>

@interface HarvesterTool : NSObject
- (void)startWithTarget:(NSString *)target;
@end

@implementation HarvesterTool

- (void)startWithTarget:(NSString *)target {
    [self fetchHTMLForURL:target];
    [self performWhoisLookupForDomain:target];
    [self resolveDNSForDomain:target];
}

- (void)fetchHTMLForURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSString *htmlContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self extractEmailsFromHTML:htmlContent];
            [self extractSubdomainsFromHTML:htmlContent usingBaseDomain:url.host];
        }
    }];
    [task resume];
}

- (void)extractEmailsFromHTML:(NSString *)html {
    NSString *emailRegex = @"[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:emailRegex options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray *matches = [regex matchesInString:html options:0 range:NSMakeRange(0, [html length])];
    for (NSTextCheckingResult *match in matches) {
        NSString *email = [html substringWithRange:match.range];
        [self saveResult:email];
    }
}

- (void)extractSubdomainsFromHTML:(NSString *)html usingBaseDomain:(NSString *)baseDomain {
    NSString *subdomainRegex = [NSString stringWithFormat:@"[a-zA-Z0-9.-]+\\.%@", baseDomain];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:subdomainRegex options:0 error:nil];
    
    NSArray *matches = [regex matchesInString:html options:0 range:NSMakeRange(0, [html length])];
    for (NSTextCheckingResult *match in matches) {
        NSString *subdomain = [html substringWithRange:match.range];
        [self saveResult:subdomain];
    }
}

- (void)performWhoisLookupForDomain:(NSString *)domain {
    NSString *apiKey = @"YOUR_API_KEY";
    NSString *urlString = [NSString stringWithFormat:@"https://www.whoisxmlapi.com/whoisserver/WhoisService?apiKey=%@&domainName=%@", apiKey, domain];
    NSURL *url = [NSURL URLWithString:urlString];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            [self saveResult:[json description]];
        }
    }];
    [task resume];
}

- (void)resolveDNSForDomain:(NSString *)domain {
    struct addrinfo hints, *res;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    if (getaddrinfo([domain UTF8String], NULL, &hints, &res) == 0) {
        struct addrinfo *p;
        for (p = res; p != NULL; p = p->ai_next) {
            char ipstr[INET6_ADDRSTRLEN];
            void *addr;
            if (p->ai_family == AF_INET) {
                struct sockaddr_in *ipv4 = (struct sockaddr_in *)p->ai_addr;
                addr = &(ipv4->sin_addr);
            } else {
                struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)p->ai_addr;
                addr = &(ipv6->sin6_addr);
            }
            inet_ntop(p->ai_family, addr, ipstr, sizeof(ipstr));
            [self saveResult:[NSString stringWithUTF8String:ipstr]];
        }
        freeaddrinfo(res);
    }
}

- (void)saveResult:(NSString *)result {
    NSString *filePath = @"/path/to/output/results.txt";
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!fileHandle) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    }
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[[result stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) return 1;
        NSString *target = [NSString stringWithUTF8String:argv[1]];
        HarvesterTool *harvester = [[HarvesterTool alloc] init];
        [harvester startWithTarget:target];
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}