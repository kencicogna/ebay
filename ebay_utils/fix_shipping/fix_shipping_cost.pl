#!/usr/bin/perl -w 
# generated by wxGlade 0.6.5 (standalone edition) on Fri Nov 30 13:55:30 2012
# To get wxPerl visit http://wxPerl.sourceforge.net/

use strict;
use LWP::UserAgent;
use LWP::Simple;
use HTTP::Request;
use HTTP::Headers;
use DBI;
use XML::Simple qw(XMLin XMLout);
use Date::Calc 'Today';
use Data::Dumper 'Dumper';			$Data::Dumper::Sortkeys = 1;
use File::Copy qw(copy move);
use POSIX;
use Getopt::Std;
use Storable 'dclone';

my %opts;
getopts('i:raDo:m:w:e:',\%opts);

my $single_item_id;
my $process_all_items = 0;
my $weight_in;

if ( defined $opts{i} ) {
	$single_item_id = $opts{i};
	$weight_in = $opts{w} ? $opts{w} : 0;
}
elsif ( defined $opts{a} ) {
  $process_all_items = 1;
}
else {
	die "must supply either option '-i <item id>' or '-a' option";
}

my $max_items           = defined $opts{m} ? $opts{m} : 0;
my $REVISE_ITEM         = defined $opts{r} ? 1 : 0;
my $DEBUG               = defined $opts{D} ? 1 : 0;
my $outfile             = defined $opts{o} ? $opts{o} : 'shipping_cost_fix.csv';
$outfile .= '.csv' if ( $outfile !~ /.*\.csv$/i );
my $noweightfile        = defined $opts{e} ? $opts{e} : 'shipping_cost_fix.noweights.csv';
$noweightfile .= '.csv' if ( $noweightfile !~ /.*\.csv$/i );

my $errfile = 'shipping_cost_fix.errors.csv';

###################################################
# EBAY API INFO                                   #
###################################################

# define the HTTP header
my $header = HTTP::Headers->new;
$header->push_header('X-EBAY-API-COMPATIBILITY-LEVEL' => '929');
$header->push_header('X-EBAY-API-DEV-NAME'  => 'd57759d2-efb7-481d-9e76-c6fa263405ea');
$header->push_header('X-EBAY-API-APP-NAME'  => 'KenCicog-a670-43d6-ae0e-508a227f6008');
$header->push_header('X-EBAY-API-CERT-NAME' => '8fa915b9-d806-45ef-ad4b-0fe22166b61e');
$header->push_header('X-EBAY-API-CALL-NAME' => '__API_CALL_NAME__');
$header->push_header('X-EBAY-API-SITEID'    => '0'); # usa
$header->push_header('Content-Type'         => 'text/xml');

my $objHeaderReviseItem = HTTP::Headers->new;
$objHeaderReviseItem->push_header('X-EBAY-API-COMPATIBILITY-LEVEL' => '929');
$objHeaderReviseItem->push_header('X-EBAY-API-DEV-NAME'  => 'd57759d2-efb7-481d-9e76-c6fa263405ea');
$objHeaderReviseItem->push_header('X-EBAY-API-APP-NAME'  => 'KenCicog-a670-43d6-ae0e-508a227f6008');
$objHeaderReviseItem->push_header('X-EBAY-API-CERT-NAME' => '8fa915b9-d806-45ef-ad4b-0fe22166b61e');
$objHeaderReviseItem->push_header('X-EBAY-API-CALL-NAME' => 'ReviseFixedPriceItem');
$objHeaderReviseItem->push_header('X-EBAY-API-SITEID'    => '0'); # usa
$objHeaderReviseItem->push_header('Content-Type'         => 'text/xml');


# eBayAuthToken
my $eBayAuthToken = 'AgAAAA**AQAAAA**aAAAAA**CQTJVA**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wHlIKoCZCBogmdj6x9nY+seQ**4EwAAA**AAMAAA**IjIgU4Mg/eixJ7OQDRd60pU4NWyjtHgmki3+78wP5Vdt8qXeUz9lAbiDgkWaTbHHxBS2J+GvPSZZ9c+24CHqWIxORvV0OK1M176YGUAUPY7YXq8Z2XSTUp+pmq7In/SjzNc17Aqg+CUZsYDn1mnyoRGyW3rT5uk6TtCStBcckV1q55Jg0JomVxUtC68NPC+4JDCqOEqHVOok7pTR8dNa7wTZiSZCoKodX7c8wnBStPkGHhw3G3ogeU0FmKudl1IMsV1zUlJ0E5dCq9GF/2wxgQQAdH29RXcVUHKDE5zAXSmUIvrmIRKG2xDOnxUSjsRMQJZ8dN/wEKXtjQK4NYCBqwmqo+7uMsUwbqjF6X320t/eksCLbG8tL+QtLN9PwrpbAUnnMHnn/LI+sEb1BaFHBI0O9eqYKJII/bVaYwFNilqq4qe1wR+qF2Ge9Fa6jYvdKMwhVvYZmily6mIDhJEX4VUQ3B9wx6tx6Bnm49/2LNblVY+toRI+rqdMnjVAQTXPeWzxmUqSK4Ql0Jn7pm0ul7v9Zt9/LYNRpjId7NoEC//q/5rvBxGIBSLe3KzrSR2r/Xuu9IMfrJbq3bvoMBpgr5Iy7+K2vXPmfXkQ3VuXocoAJIvuZTrSLIY6DSqfdc5oxk0RObGcShP+grojI1FpWGULDDYM5Uxlbj3FNSGc7X/U2MslXt0dZ5Ao0dtf4oz63oEHQV1sfEToouUEhML7Sz9exfEfZy35LqR6RuTOXDyTG1gFweFCkK6F54eZgdLZ';

# define the XML request
my $request_reviseitem_default = <<END_XML;
<?xml version='1.0' encoding='utf-8'?>
<ReviseFixedPriceItemRequest xmlns="urn:ebay:apis:eBLBaseComponents">
<RequesterCredentials>
  <eBayAuthToken>$eBayAuthToken</eBayAuthToken>
</RequesterCredentials>
<WarningLevel>High</WarningLevel>
<Item>
<ItemID>__ItemID__</ItemID>
__SHIPPING_DETAILS__
</Item>
</ReviseFixedPriceItemRequest>
END_XML
#__Quantity_Info__

my $request_getitem_default = <<END_XML;
<?xml version='1.0' encoding='utf-8'?>
<GetItemRequest xmlns="urn:ebay:apis:eBLBaseComponents">
<RequesterCredentials>
  <eBayAuthToken>$eBayAuthToken</eBayAuthToken>
</RequesterCredentials>
<WarningLevel>High</WarningLevel>
<ItemID>__ItemID__</ItemID>
</GetItemRequest>
END_XML

my $request_getmyebayselling = <<END_XML;
<?xml version='1.0' encoding='utf-8'?>
<GetMyeBaySellingRequest xmlns="urn:ebay:apis:eBLBaseComponents">
<RequesterCredentials>
  <eBayAuthToken>$eBayAuthToken</eBayAuthToken>
</RequesterCredentials>
<WarningLevel>High</WarningLevel>
<ActiveList>
	<Include>true</Include>
	<Pagination>
		<EntriesPerPage>200</EntriesPerPage>
		<PageNumber>__PAGE_NUMBER__</PageNumber>
	</Pagination>
</ActiveList>
</GetMyeBaySellingRequest>
END_XML
#<OutputSelector>ItemID PaginationResult</OutputSelector>

my $request_GetShippingDiscountProfiles = <<END_XML;
<?xml version='1.0' encoding='utf-8'?>
<GetShippingDiscountProfilesRequest xmlns="urn:ebay:apis:eBLBaseComponents">
<RequesterCredentials>
  <eBayAuthToken>$eBayAuthToken</eBayAuthToken>
</RequesterCredentials>
<WarningLevel>High</WarningLevel>
</GetShippingDiscountProfilesRequest>
END_XML


########################################
# SQL
########################################

# get weight from BLACKTHORNE (Should represent all ALL Ebay listings)!
my $sql_get_weight = <<END_SQL;
	select L.ebayID, L.Title, isnull(isnull(S.weight, L.weight),0) as weight
	from
	(SELECT title, max(Weight) as weight FROM TTY_StorageLocation group by title) S,
	(select distinct l.ebayID, l.title, (l.WeightLbs*16)+l.WeightOz as weight 
		 from listings l
		JOIN ListingStatus s on (l.StatusID = s.StatusID)
		where statusFamily='running'
		and isArchive=0) L
	where S.title = L.title
END_SQL


###########################################################
# END EBAY API INFO                                       #
###########################################################

# Open output file
open my $outfh, '>', $outfile or die "can't open file";
open my $noweight_fh, '>', $noweightfile or die "can't open file";
open my $err_fh, '>', $errfile or die "can't open file";

my $dbh;
my $sth;
my $item_weights = {};

# Get Item Weights
if ( $single_item_id && $weight_in ) {
	# short cut, if the user is only processing one item and has provide the weight
	#            also a way around not having access to the database when testing
	$item_weights->{$single_item_id}->{weight} = $weight_in;
}
else {
	# Connect to Database
	eval {
		# Open database connection
		$dbh =
		DBI->connect( "DBI:ODBC:BTData_PROD_SQLEXPRESS",
									'shipit',
									'shipit',
									{ 
										RaiseError       => 0, 
										AutoCommit       => 1, 
										FetchHashKeyName => 'NAME_lc',
										LongReadLen      => 32768,
									} 
							)
		|| die "\n\nDatabase connection not made: $DBI::errstr\n\n";
	};

	die "$@"
		if ($@);

	# Get all item weights from tty_storageLocation
	$sth = $dbh->prepare( $sql_get_weight) or die "can't prepare stmt";
	$sth->execute() or die "can't execute stmt";
	$item_weights = $sth->fetchall_hashref('ebayid') or die "can't fetch results";						
}

my $response_hash;
my $request;
my %all_shipping_profiles;

# Get Ebay Flat shipping discount profiles
$header->remove_header('X-EBAY-API-CALL-NAME');
$header->push_header('X-EBAY-API-CALL-NAME' => 'GetShippingDiscountProfiles');
$request = $request_GetShippingDiscountProfiles;
$response_hash = submit_request( $request, $header );
my $FlatShippingDiscount = $response_hash->{FlatShippingDiscount}->{DiscountProfile};
for my $sp ( @{$FlatShippingDiscount} ) {
	my $key =  sprintf( "%0.2f", $sp->{EachAdditionalAmount} ); 
	$all_shipping_profiles{ "$key" }->{EachAdditionalAmount} = $sp->{EachAdditionalAmount};
	$all_shipping_profiles{ "$key" }->{DiscountProfileName} = $sp->{DiscountProfileName};
	$all_shipping_profiles{ "$key" }->{DiscountProfileID} = $sp->{DiscountProfileID};
}

# GET LIST OF ALL ITEMS *** FROM EBAY ***
$header->remove_header('X-EBAY-API-CALL-NAME');
$header->push_header('X-EBAY-API-CALL-NAME' => 'GetMyeBaySelling');

my @all_items;
my $pagenumber=1;
my $maxpages=1000000;

if ( $process_all_items ) {
	while ( $pagenumber <= $maxpages ) {
		$request = $request_getmyebayselling;
		$request =~ s/__PAGE_NUMBER__/$pagenumber/;
		$response_hash = submit_request( $request, $header );
		for my $i ( @{$response_hash->{ActiveList}->{ItemArray}->{Item}} ) {
			push(@all_items, $i->{ItemID});
		}
		if ($pagenumber==1) {
			$maxpages = $response_hash->{ActiveList}->{PaginationResult}->{TotalNumberOfPages};
		}
		$pagenumber++;
	}
}
else {
	@all_items = ($single_item_id);
}
print STDERR "Total Items: ",scalar @all_items,"\n";

# Write output header row to output file
print $outfh qq/"eBayItemID","Title","Oz.","New Shipping Cost R.O.W.","New ShippingCost C.A."/;
print $noweight_fh qq/"eBayItemID","Title"/;
print $err_fh qq/"eBayItemID","Title","Error Message"/;

#
# Loop over each item from Ebay
#
my $item_count=0;
for my $item_id ( @all_items ) {

	$item_count++;
	# GET SINGLE ITEM DETAILS
	$request = $request_getitem_default;
	$request =~ s/__ItemID__/$item_id/;
	$header->remove_header('X-EBAY-API-CALL-NAME');
	$header->push_header  ('X-EBAY-API-CALL-NAME' => 'GetItem');
	$response_hash = submit_request( $request, $header );

	print "\nGetItem Response: ", Dumper($response_hash), "\n\n" 
		if $DEBUG;

	# Display shipping info
	my $r = $response_hash->{Item};
	my $title  = $r->{Title};

	# Get weight from TTY_StorageLocation table
	my $ozs = 0;
	if ( defined $item_weights->{$item_id} && $item_weights->{$item_id} ) {
	  $ozs = $item_weights->{$item_id}->{weight};
	}
	else {
    print STDERR "\nWarning: Not on TTY_StorageLocation table.";
		print STDERR "\n   ITEM ID: '$item_id' - TITLE: '$title'";
		print $noweight_fh "\n$item_id,$title";
		#next; --> moved this down by revise item, to give the item the opportunity to fall out also do to not having intl shipping info
	}

	# mailclass/price
	my $spd = $r->{ShippingPackageDetails};
	my $sd  = $r->{ShippingDetails};
	my $shipping_details = dclone($sd);

	#
	## INTERNATIONAL SERVICES
	#
	my $addl_item_cost;
	my $addl_item_cost_profile;
	my $new_cost_row;
	my $new_cost_ca;

	if ( defined $sd->{InternationalShippingServiceOption} ) { # this is optional
		# Calculate new rates and add them to $shipping_details
		$new_cost_row  = 2.49 + (.50 * $ozs);
		$new_cost_ca   = 2.49 + (.35 * $ozs);

		# Calculate addl_item_cost and addl_item_cost_profile for all intl locations
		$addl_item_cost = (.50 * $ozs) + .50;

		$new_cost_ca = $addl_item_cost
		  if ( $new_cost_ca < $addl_item_cost );

		my $addl_item_cost_string = sprintf("%0.2f", $addl_item_cost );
		if ( defined $all_shipping_profiles{ $addl_item_cost_string } ) { 
			$addl_item_cost_profile = $all_shipping_profiles{ $addl_item_cost_string };
		} else {
			print STDERR "\nWARNING: NO SHIPPING PROFILE FOUND FOR COST '$addl_item_cost_string'";
			print STDERR "\n  ($item_id) $title\n";
			print $err_fh qq/\n$item_id,"$title","No shipping profile for cost '$addl_item_cost_string'"/;
			next;
		}

		$sd->{InternationalShippingDiscountProfileID} = $addl_item_cost_profile->{DiscountProfileID};
    $sd->{InternationalFlatShippingDiscount} = 
																			{
                                       'DiscountName' => 'EachAdditionalAmount',
                                       'DiscountProfile' => {
                                                            'DiscountProfileID' => $addl_item_cost_profile->{DiscountProfileID},
                                                            'DiscountProfileName' => $addl_item_cost_profile->{DiscountProfileName},
                                                            'EachAdditionalAmount' => [ "$addl_item_cost" ]
                                                            }
                                     };
		

    $sd->{InternationalShippingServiceOption} = [
                                        {
                                          'ShipToLocation' => [
                                                              'Worldwide'
                                                              ],
                                          'ShippingService' => 'OtherInternational',
                                          'ShippingServiceAdditionalCost' => [ $addl_item_cost ],
                                          'ShippingServiceCost' => [ "$new_cost_row" ],
                                          'ShippingServicePriority' => '1'
                                        },
                                        {
                                          'ShipToLocation' => [
                                                              'CA'
                                                              ],
                                          'ShippingService' => 'OtherInternational',
                                          'ShippingServiceAdditionalCost' => [ $addl_item_cost ],
                                          'ShippingServiceCost' => [ "$new_cost_ca" ],
                                          'ShippingServicePriority' => '2'
                                        },
                                      ];

	}
	else {
		# No international shipping specified
		#print STDERR Dumper($r);
	  print STDERR "\nWARNING: NO INTL SHIPPING INFORMATION IN LISTING";
		print STDERR "\n  ($item_id) $title\n";

	  print $err_fh qq/\n$item_id,"$title","No International shipping info (calculated weight?)"/;
		next;
	}

	# skip this record if we couldn't find a weight in TTY_StorageLocation table
	next if ( ! $ozs );

	# Fix content tags (before revising item -- probably wouldn't have to do this if we XMLin'd with different options)
	delete $sd->{CalculatedShippingRate};
	my $flat_addl_amount = $sd->{FlatShippingDiscount}->{DiscountProfile}->{EachAdditionalAmount}->{content} || '0';
	$sd->{FlatShippingDiscount}->{DiscountProfile}->{EachAdditionalAmount} = $flat_addl_amount;

	for my $sso ( @{ $sd->{ShippingServiceOptions} } ) {
		my $sso_ss_addl_cost = $sso->{ShippingServiceAdditionalCost}->{content} || '0';
		$sso->{ShippingServiceAdditionalCost} = $sso_ss_addl_cost;

		my $sso_ss_cost = $sso->{ShippingServiceCost}->{content} || '0';
		$sso->{ShippingServiceCost} = $sso_ss_cost;
	}

	# Convert the hash into XML
  my $shipping_details_xml = XMLout($sd, NoAttr=>1, RootName=>'ShippingDetails', KeyAttr=>{});

	if ( $DEBUG ) { 
		print "\n\nShippingDetails:\n",Dumper($sd);
		print "\n\nShipping Details XML:\n",Dumper($shipping_details_xml);
	}

	#
	# REVISE ITEM
	#
	if ( $REVISE_ITEM ) {
		my $request = $request_reviseitem_default;
		$request =~ s/__ItemID__/$item_id/;
		$request =~ s/__SHIPPING_DETAILS__/$shipping_details_xml/;

		# print "\nReviseItem Request: ", Dumper($request), "\n\n";

		eval {
			my $r = submit_request( $request, $objHeaderReviseItem, 1 ); # return error object if the request fails
			if ( $r->{LongMessage} ) {
				my $error = $r->{LongMessage};
				print $err_fh qq/\n$item_id,"$title","$error"/;
				next;
			}
		};
		if ( $@ ) {
				print $err_fh qq/\n$item_id,"$title","ERROR: Submit ReviseFixedPriceItem failed. $@"/;
				next;
		}

		my $upd_eBT = <<SQL;
UPDATE ShippingTemplates
SET IntShipToLocation1 = 'Worldwide'
  , IntShippingService1  = 29
  , IntShippingServiceAdditionalCost1 = $addl_item_cost
  , IntShippingServiceCost1 = $new_cost_row
  , IntShipToLocation2 = 'CA'
  , IntShippingService2 = 29
  , IntShippingServiceAdditionalCost2 = $addl_item_cost
  , IntShippingServiceCost2 = $new_cost_ca
  , IntShipToLocation3 = null
  , IntShippingService3 = 15
  , IntShippingServiceAdditionalCost3 = 0
  , IntShippingServiceCost3 = 0
  , IntShipToLocation4 = null
  , IntShippingService4 = 15
  , IntShippingServiceAdditionalCost4 = 0
  , IntShippingServiceCost4 = 0
  , IntShipToLocation5 = null
  , IntShippingService5 = 15
  , IntShippingServiceAdditionalCost5 = 0
  , IntShippingServiceCost5 = 0
  , InternationalShippingType = 1
	, ApplyInternationalShippingDiscountProfileID = 1
WHERE shippingTemplateID in (SELECT l.shippingTemplateID 
                               FROM Listings l
                               JOIN ListingStatus s ON (l.StatusID = s.StatusID)
                              WHERE s.statusFamily='running' 
                                AND l.isArchive=0
                                AND l.title = ? )
SQL
  
	# print "\n$upd_eBT\n\n";
	$sth = $dbh->prepare( $upd_eBT ) or die "can't prepare stmt";
	$sth->execute($title) or die "can't execute stmt";
	}

	# Write Output file
	print STDERR "$item_count\t$item_id  $title\n";
	print $outfh qq/\n$item_id,"$title",$ozs,$new_cost_row,$new_cost_ca/;

	if ( $max_items and $item_count >= $max_items ) {
		print "\nMax Items  : $max_items";
		print "\nItem Count : $max_items";
		last;
	}
}

close $outfh;
close $noweight_fh;
close $err_fh;



exit;

####################################################################################################
sub submit_request {
	my ($request, $objHeader,$return_error) = @_;
  my ($objRequest, $objUserAgent, $objResponse);
  my $request_sent_attempts = 0;

  RESEND_REQUEST:
  $request_sent_attempts++;

  # Create UserAgent and Request objects
  $objUserAgent = LWP::UserAgent->new;
  $objRequest   = HTTP::Request->new(
    "POST",
    "https://api.ebay.com/ws/api.dll",
    $objHeader,
    $request
  );

	#print "\n objHeader : ",Dumper($objHeader);
	#print "\n request   : ",Dumper($request);
	#print "\n objRequest: ",Dumper($objRequest);

  # Submit Request
  $objResponse = $objUserAgent->request($objRequest);		# SEND REQUEST

  # Parse Response object to get Acknowledgement 
	my $content =  $objResponse->content;
	my $response_hash = XMLin( "$content",  ForceArray=>['InternationalShippingServiceOption','ShippingServiceOptions','ShipToLocation'] );
	#my $response_hash = XMLin( $content );
  my $ack = $response_hash->{Ack};

  if (!$objResponse->is_error && $ack =~ /success/i ) {
    return $response_hash;
  }
  else {
		print "\n\n";
    print "\nStatus          : FAILED";
	  print "\nRequest         : ", Dumper( $request );
    print "\nResponse msg.   : ", Dumper( $response_hash->{Errors} );
		#print $objResponse->error_as_HTML;

    # Resend update request
    if ( $request_sent_attempts < 1 ) {
      print  "Attempting to resend update request.\n";
      goto RESEND_REQUEST;
    }

		# Return error information if requested
		if ( $return_error ) { 
			return $response_hash->{Errors}; 
		} else { 
			die; 
		}

  }

} # end submit_request()

