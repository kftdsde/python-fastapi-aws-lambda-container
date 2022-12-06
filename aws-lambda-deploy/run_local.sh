prof="--profile kifiya --region us-east-1"

#
function get_ssm_secret() {
    #echo "reading key=$1 from aws secret manager"
    res=$(aws secretsmanager get-secret-value \
       	      --secret-id $1  \
	      --query SecretString \
              --output text $prof | jq -r '.API_KEY')
    echo $res
}

ssmappkey="dev/csengine-api-key"
appkey=$(get_ssm_secret $ssmappkey)


serverless plugin install -n serverless-add-api-key
serverless plugin install -n serverless-vpc-discovery

sls deploy --stage dev --region us-east-1 --aws-profile kifiya
