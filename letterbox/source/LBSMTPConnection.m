/*
 * MailCore
 *
 * Copyright (C) 2007 - Matt Ronge
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the MailCore project nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRELB, INDIRELB, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRALB, STRILB
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#import "LBSMTPConnection.h"
#import <libetpan/libetpan.h>
#import "LBAddress.h"
#import "LBMessage.h"
#import "LetterBoxTypes.h"

#import "LBSMTP.h"
#import "LBESMTP.h"

//TODO Add more descriptive error messages using mailsmtp_strerror
@implementation LBSMTPConnection
+ (void)sendMessage:(LBMessage *)message server:(NSString *)server username:(NSString *)username
                    password:(NSString *)password port:(unsigned int)port useTLS:(BOOL)tls useAuth:(BOOL)auth {
      mailsmtp *smtp = NULL;
    smtp = mailsmtp_new(0, NULL);
    assert(smtp != NULL);

    LBSMTP *smtpObj = [[LBESMTP alloc] initWithResource:smtp];
    @try {
        [smtpObj connectToServer:server port:port];
        if ([smtpObj helo] == false) {
            /* The server didn't support ESMTP, so switching to STMP */
            [smtpObj release];
            smtpObj = [[LBSMTP alloc] initWithResource:smtp];
            [smtpObj helo];
        }
        if (tls)
            [smtpObj startTLS];
        if (auth)
            [smtpObj authenticateWithUsername:username password:password server:server];

        [smtpObj setFrom:[[[message from] anyObject] email]];

        /* recipients */
        NSMutableSet *rcpts = [NSMutableSet set];
        [rcpts unionSet:[message to]];
        [rcpts unionSet:[message bcc]];
        [rcpts unionSet:[message cc]];
        [smtpObj setRecipients:rcpts];
     
        /* data */
        [smtpObj setData:[message render]];
    }
    @finally {
        [smtpObj release];    
        mailsmtp_free(smtp);
    }
}
@end