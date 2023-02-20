import {getSignedCookies} from "@aws-sdk/cloudfront-signer";
import {GetParameterCommand, SSMClient} from "@aws-sdk/client-ssm";

const ssmClient = new SSMClient({region: "us-east-1"});
const cache = {}

const loadParameter = async (key, WithDecryption = false) => {
    const command = new GetParameterCommand({Name: key, WithDecryption: WithDecryption})
    const {Parameter} = await ssmClient.send(command)
    return Parameter.Value;
};

function getExpirationTime() {
    const date = new Date();
    let hours = date.getHours() + 8;
    return new Date(date.getFullYear(), date.getMonth(), date.getDate(), hours, date.getMinutes(), date.getSeconds());
}

function getSignedCookie(url, keyPairId, privateKey) {
    const expirationTime = getExpirationTime();
    return getSignedCookies({
        url: url,
        keyPairId: keyPairId,
        privateKey: privateKey,
        dateLessThan: expirationTime.toISOString()
    });
}

export const handler = async (event, context) => {
    console.log("Context: " + JSON.stringify(context))
    // Remove region from functionName
    const functionName = context.functionName.substring(context.functionName.indexOf(".") + 1)
    if (cache.keyPairId == null) {
        cache.keyPairId = await loadParameter(`/purple/cloudfront/lambda/${functionName}/keyPairId`);
    }
    if (cache.privateKey == null) {
        cache.privateKey = await loadParameter(`/purple/cloudfront/lambda/${functionName}/privateKey`, true);
    }
    const {keyPairId, privateKey} = cache;

    const request = event.Records[0].cf.request;
    const domain = request.headers.host[0].value
    let searchString = ".pkar/web/";
    console.log("Domain: " + domain);
    const end = request.uri.lastIndexOf(searchString);
    const path = request.uri.substring(0, end > 0 ? end + searchString.length : undefined)
    console.log("Path: " + path);
    const url = "https://" + domain + path
    console.log("URL: " + url);
    console.log("KeyPairId: " + keyPairId);
    console.log("Private Key: " + privateKey);
    const signedCookie = getSignedCookie(url, keyPairId, privateKey);

    const response = event.Records[0].cf.response;
    response.headers['set-cookie'] = [
        {
            key: "Set-Cookie",
            value: `CloudFront-Policy=${signedCookie['CloudFront-Policy']};Domain=${domain};Path=${path};Secure;HttpOnly;SameSite=Lax`
        }, {
            key: "Set-Cookie",
            value: `CloudFront-Key-Pair-Id=${signedCookie['CloudFront-Key-Pair-Id']};Domain=${domain};Path=${path};Secure;HttpOnly;SameSite=Lax`
        }, {
            key: "Set-Cookie",
            value: `CloudFront-Signature=${signedCookie['CloudFront-Signature']};Domain=${domain};Path=${path};Secure;HttpOnly;SameSite=Lax`
        }
    ];

    return response;
};
