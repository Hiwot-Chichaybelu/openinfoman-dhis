module namespace page = 'http://basex.org/modules/web-page';

(:Import other namespaces.  :)
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";
import module namespace csd_dm = "https://github.com/openhie/openinfoman/csd_dm";
import module namespace csd_mcs = "https://github.com/openhie/openinfoman/csd_mcs";

declare namespace csd = "urn:ihe:iti:csd:2013";


declare function page:is_dhis($search_name) {
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $ext := $function//csd:extension[  @urn='urn:openhie.org:openinfoman:adapter' and @type='dhis2']
  return (count($ext) > 0) 
};

declare
  %rest:path("/CSD/adapter/dhis2/{$search_name}")
  %output:media-type("xhtml")
  function page:show_endpoints($search_name) 
{  
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  return 
    if (not(page:is_dhis($search_name)))
    then ("Not a DHIS2 function")
    else 
      let 
	$contents :=
	  <div>
	    <h2>DHIS2 Aggregating Documents</h2>
            <ul>
              {
  		for $doc_name in csd_dm:registered_documents($csd_webconf:db,true())      
		return
  		<li>
		  <a href="{$csd_webconf:baseurl}CSD/adapter/dhis2/{$search_name}/{$doc_name}">{string($doc_name)}</a>
		</li>
	      }
	    </ul>
	  </div>
       return $contents

 
};



declare
  %rest:path("/CSD/adapter/dhis2/{$search_name}/{$doc_name}")
  %output:media-type("xhtml")
  function page:show_endpoints($search_name,$doc_name) 
{  
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  return 
    if (not(page:is_dhis($search_name)) ) 
    then ('Not a DHIS2 Compatible stored function'    )
    else 
      let $contents := 
      <div>
        <h2>Aggregate Health Worker Data</h2>
	  {
	    let $url := concat($csd_webconf:baseurl, "CSD/adapter/dhis2/",$search_name, "/", $doc_name, "/aggregate")
	    return <a href="{$url}">Get DXF</a>
	  }
      </div>
      return $contents
};


declare
  %rest:path("/CSD/adapter/dhis2/{$search_name}/{$doc_name}/aggregate") 
  function page:execute2($search_name,$doc_name) 
{
  let $function := csr_proc:get_function_definition($csd_webconf:db,$search_name)
  let $assName := "dhis.org:orgid"
  return 
    if (not(page:is_dhis($search_name)) ) 
      then ('Not a DHIS2 Compatible stored function'    )
    else 
      let $doc :=  if ($doc_name =  $csd_mcs:merged_services_doc)
	then
	db:open($csd_webconf:db,$doc_name) 
      else 
	csd_dm:open_document($csd_webconf:db,$doc_name)


      let $careServicesRequest := 
        <csd:careServicesRequest>
	  <csd:function urn="{$search_name}" resource="{$doc_name}" base_url="{$csd_webconf:baseurl}">
	    <csd:requestParams >
	      <assigningAuthorityName>{$assName}</assigningAuthorityName>
	    </csd:requestParams>
	  </csd:function>
	</csd:careServicesRequest>
      return csr_proc:process_CSR_stored_results($csd_webconf:db, $doc,$careServicesRequest)
};

