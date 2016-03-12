package EbayConfig;
#
# ES - Ebay Setup
#

use HTTP::Headers;

our $ES_compatibility_level = '949';

our $ES_http_header = HTTP::Headers->new;
$ES_http_header->push_header('X-EBAY-API-COMPATIBILITY-LEVEL' => $ES_compatibility_level );
$ES_http_header->push_header('X-EBAY-API-DEV-NAME'  => 'd57759d2-efb7-481d-9e76-c6fa263405ea');
$ES_http_header->push_header('X-EBAY-API-APP-NAME'  => 'KenCicog-a670-43d6-ae0e-508a227f6008');
$ES_http_header->push_header('X-EBAY-API-CERT-NAME' => '8fa915b9-d806-45ef-ad4b-0fe22166b61e');
$ES_http_header->push_header('X-EBAY-API-CALL-NAME' => '__API_CALL_NAME__');
$ES_http_header->push_header('X-EBAY-API-SITEID'    => '0'); # usa
$ES_http_header->push_header('Content-Type'         => 'text/xml');

our $ES_eBayAuthToken = 'AgAAAA**AQAAAA**aAAAAA**CQTJVA**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wHlIKoCZCBogmdj6x9nY+seQ**4EwAAA**AAMAAA**IjIgU4Mg/eixJ7OQDRd60pU4NWyjtHgmki3+78wP5Vdt8qXeUz9lAbiDgkWaTbHHxBS2J+GvPSZZ9c+24CHqWIxORvV0OK1M176YGUAUPY7YXq8Z2XSTUp+pmq7In/SjzNc17Aqg+CUZsYDn1mnyoRGyW3rT5uk6TtCStBcckV1q55Jg0JomVxUtC68NPC+4JDCqOEqHVOok7pTR8dNa7wTZiSZCoKodX7c8wnBStPkGHhw3G3ogeU0FmKudl1IMsV1zUlJ0E5dCq9GF/2wxgQQAdH29RXcVUHKDE5zAXSmUIvrmIRKG2xDOnxUSjsRMQJZ8dN/wEKXtjQK4NYCBqwmqo+7uMsUwbqjF6X320t/eksCLbG8tL+QtLN9PwrpbAUnnMHnn/LI+sEb1BaFHBI0O9eqYKJII/bVaYwFNilqq4qe1wR+qF2Ge9Fa6jYvdKMwhVvYZmily6mIDhJEX4VUQ3B9wx6tx6Bnm49/2LNblVY+toRI+rqdMnjVAQTXPeWzxmUqSK4Ql0Jn7pm0ul7v9Zt9/LYNRpjId7NoEC//q/5rvBxGIBSLe3KzrSR2r/Xuu9IMfrJbq3bvoMBpgr5Iy7+K2vXPmfXkQ3VuXocoAJIvuZTrSLIY6DSqfdc5oxk0RObGcShP+grojI1FpWGULDDYM5Uxlbj3FNSGc7X/U2MslXt0dZ5Ao0dtf4oz63oEHQV1sfEToouUEhML7Sz9exfEfZy35LqR6RuTOXDyTG1gFweFCkK6F54eZgdLZ';


1;
