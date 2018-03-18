## Gets elb hosted zone ID
import json
import sys

obj=json.load(sys.stdin)
endpoint = sys.argv[1]

lb = [x for x in obj["LoadBalancerDescriptions"] if x.get("DNSName") == endpoint][0]

print lb.get("CanonicalHostedZoneNameID")
