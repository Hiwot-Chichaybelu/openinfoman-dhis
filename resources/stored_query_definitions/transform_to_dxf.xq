import module namespace dxf2csd = "http://dhis2.org/csd/dxf/2.0";
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace csd_dm = "https://github.com/openhie/openinfoman/csd_dm";
import module namespace svs_lsvs = "https://github.com/openhie/openinfoman/svs_lsvs";
import module namespace util = "https://github.com/openhie/openinfoman-dhis/util";
import module namespace functx = "http://www.functx.com";

declare namespace svs = "urn:ihe:iti:svs:2008";
declare namespace csd = "urn:ihe:iti:csd:2013";
declare namespace dxf = "http://dhis2.org/csd/dxf/2.0";

declare variable $careServicesRequest as item() external; 

let $doc_name := string($careServicesRequest/@resource)
let $doc := csd_dm:open_document($csd_webconf:db,$doc_name)

let $facilities := $doc/csd:CSD/csd:facilityDirectory/csd:facility
let $svcs := $doc/csd:CSD/csd:serviceDirectory/csd:service
let $orgs := $doc/csd:CSD/csd:organizationDirectory/csd:organization
let $provs := $doc/csd:CSD/csd:providerDirectory/csd:provider


let $fac_type_ids := ("1.3.6.1.4.1.21367.200.103")

let $org_unit_groups :=   
  for $fac_type_id in $fac_type_ids	  
  let $fac_types :=  svs_lsvs:get_single_version_value_set($csd_webconf:db,string($fac_type_id) )	  
  return
    for $concept in $fac_types//svs:Concept
    let $code := string($concept/@code)
    let $scheme := string($concept/@codeSystem)
    let $name := string($concept/@displayName)
    return <dxf:organisationUnitGroup code="{$code}" name="{$name}" codeSystem="{$scheme}"/>

return 
    <dxf:metaData>
      <dxf:users>
      {
	for $prov in $provs

	let $dhis_url := string(($prov/csd:record/@sourceDirectory)[1])
	let $dhis_id :=  ($prov/csd:otherID[@assigningAuthorityName=concat($dhis_url,"/api/User") and @code="id"])[1]/text()	  
	let $namespace_uuid := util:uuid_generate($dhis_url,$util:namespace_uuid)
	let $oid := concat('2.25.',util:hexdec(util:uuid_generate('rootoid',$namespace_uuid)))	

	let $name := ($prov/csd:demographic/csd:name/csd:commonName)[1]
	let $surname := ($prov/csd:demographic/csd:name/csd:surname)[1]
	let $firstname := ($prov/csd:demographic/csd:name/csd:firstname)[1]
	let $phone := ($prov/csd:contactPoint/csd:codedType[@code="BP" and @codingScheme="urn:ihe:iti:csd:2013:contactPoint"])[1]/text()
	let $email := ($prov/csd:contactPoint/csd:codedType[@code="EMAIL" and @codingScheme="urn:ihe:iti:csd:2013:contactPoint"])[1]/text()
	let $ag_oid := concat($oid,'.4')
	let $ur_oid := concat($oid,'.1')
	let $urs := 
	   for $o_id in $prov/csd:codedType[@codingScheme = $ur_oid]
	   return <dxf:userRole id="{string($o_id/@code)}"/>
	let $uags := 
	   for $o_id in $prov/csd:codedType[@codingScheme = $ag_oid]
	   return <dxf:userAuthorityGroup id="{string($o_id/@code)}"/>
	let $orgs := 
	  for $org in $prov/csd:organizations/csd:organization
	  let $ou_uuid := 
	    $facilities([@entityID = $org/@entityID]/csd:otherID[@assigningAuthorityName = concat($dhis_url,"/api/organisationUnit") and @code="uuid"])[1]/text()
	  return 
	    if (functx:all-whitespace($ou_uuid)) 
	    then () 
	    else  <dxf:organisationUnit uuid="{$ou_uuid}"/>


	return
	  <dxf:user name="{$name}" >
	    {if (functx:all-whitespace($dhis_id)) then () else  @id}
	    <dxf:surname>{$surname}</dxf:surname>
	    <dxf:firstName>{$firstname}</dxf:firstName>
	    {if (functx:all-whitespace($email)) then () else <dxf:email>{$email}</dxf:email>}
	    {if (functx:all-whitespace($phone)) then () else <dxf:phoneNumber>{$email}</dxf:phoneNumber>}
	    <dxf:userCredenitals>
	      <dxf:userRoles>{$urs}</dxf:userRoles>
	      <dxf:userAuthorityGroups>{$uags}</dxf:userAuthorityGroups>
	    </dxf:userCredenitals>
	    { () 
	      (: INSERT  <username>SOMETHING</username> :)
	    }
	    {$orgs}
	  </dxf:user>
        }
      </dxf:users>
      <dxf:userRoles>
	{
	  let $oids := 
	    for $dhis_url in distinct-values($provs/csd:record/@sourceDirectory)
	    let $namespace_uuid := util:uuid_generate($dhis_url,$util:namespace_uuid)
	    let $oid := concat('2.25.',util:hexdec(util:uuid_generate('rootoid',$namespace_uuid)))	
	    return $oid
	  
	  return 
	  for $oid in $oids
            let $ur_oid := concat($oid,'.1')
	    let $svs := svs_lsvs:get_single_version_value_set($csd_webconf:db,$ur_oid)
	    return
	      if (not(exists($svs)))
	      then ()
              else 
		for $val in $svs//svs:concept
		return 
		  <dxf:userRole name="{$val/@displayName}" id="{$val/@code}">
		    <dxf:description>{string($val/@displayName)}</dxf:description>
		  </dxf:userRole>
	}
      </dxf:userRoles>
      <dxf:userAuthorityGroups>
	{
	  let $oids := 
	    for $dhis_url in distinct-values($provs/csd:record/@sourceDirectory)
	    let $namespace_uuid := util:uuid_generate($dhis_url,$util:namespace_uuid)
	    let $oid := concat('2.25.',util:hexdec(util:uuid_generate('rootoid',$namespace_uuid)))	
	    return $oid
	  
	  return 
	  for $oid in $oids
            let $ag_oid := concat($oid,'.4')
	    let $svs := svs_lsvs:get_single_version_value_set($csd_webconf:db,$ag_oid)
	    return
	      if (not(exists($svs)))
	      then ()
              else 
		for $val in $svs//svs:concept
		return 
		  <dxf:userAuthorityGroup name="{$val/@displayName}" id="{$val/@code}">
		    <dxf:description>{string($val/@displayName)}</dxf:description>
		  </dxf:userAuthorityGroup>
	}
      </dxf:userAuthorityGroups>




      <dxf:organisationUnits>
        {	 
	  for $org in dxf2csd:ensure_properly_ordered_orgs($orgs) 
	  let $dhis_url := string($org/csd:record/@sourceDirectory)
	  let $dhis_uuid := ($org/csd:otherID[@assigningAuthorityName=concat($dhis_url,"/api/organisationUnit") and @code="uuid"])[1]
	  let $level := dxf2csd:get_level($doc,$org)
	  let $name := $org/csd:primaryName/text()

	  let $uuid := 
	    if (functx:all-whitespace($dhis_uuid))
	    then dxf2csd:extract_uuid_from_entityid(string($org/@entityID))
	    else string($dhis_uuid)

	  let $id := dxf2csd:extract_id_from_entityid(string($org/@entityID)) 
	  let $created := dxf2csd:fixup_date($org/csd:record/@created)
	  let $lm := dxf2csd:fixup_date($org/csd:record/@updated)

	  let $porg_id := $org/csd:parent/@entityID
	  let $porg_dhis_uuid := ($org/csd:otherID[@assigningAuthorityName=concat($dhis_url,"/api/organisationUnit") and @code="uuid"])[1]
	  let $parent :=
	    if (functx:all-whitespace($porg_id))
	    then () (: no parent :)
	    else if (not(functx:all-whitespace($porg_dhis_uuid)))
	    then <dxf:parent id="{$porg_dhis_uuid}"/>
	    else <dxf:parent id="{dxf2csd:extract_id_from_entityid(string($porg_id))}"/>
	  return 
	    if (functx:all-whitespace($uuid))
	    then ()
	    else <organisationUnit 
              level="{$level}"
	      name="{$name}"
	      shortName="{substring($name,1,50)}"
	      uuid="{$uuid}" 
	      id="{$id}"
	      lastUpdated="{$lm}"
	      created="{$created}"
	      >
	    {$parent}
	  </organisationUnit>
	}
        {
	  for $fac in $facilities
	  (: remove the facilities that have already been created from a DHIS2 org unit:)
	  let $dhis_url := string($fac/csd:record/@sourceDirectory)
	  let $dhis_uuid := ($fac/csd:otherID[@assigningAuthorityName=concat($dhis_url,"/api/organisationUnit") and @code="uuid"])[1]
	  let $dhis_id := ($fac/csd:otherID[@assigningAuthorityName=concat($dhis_url,"/api/organisationUnit") and @code="id"])[1]
	  let $org := 
	    if (functx:all-whitespace($dhis_uuid))
	    then ()
	    else ($orgs[./csd:otherID[@assigningAuthorityName=concat($dhis_url,"/api/organisationUnit") and @code="uuid" and ./text() = $dhis_uuid]])[1]
	  where not(exists($org))
	  return 
  	    let $level := dxf2csd:get_level($doc,$fac)
	    let $name := $fac/csd:primaryName/text()
	    let $uuid := 
	      if (functx:all-whitespace($dhis_uuid))
	      then dxf2csd:extract_uuid_from_entityid(string($fac/@entityID))
	      else string($dhis_uuid)
            let $id := 
	      if (functx:all-whitespace($dhis_id))
	      then dxf2csd:extract_id_from_entityid(string($fac/@entityID)) 
	      else string($dhis_id)
	    let $created := dxf2csd:fixup_date($fac/csd:record/@created)
	    let $lm := dxf2csd:fixup_date($fac/csd:record/@updated)

	    (: in CSD we can have multiple "parents" but not so DXF.  We just choose the first one    :)
	    let $org_id := ($orgs[@entityID = ($fac/csd:organizations/csd:organization)[1]/@entityID ])[1]
	    let $org := $orgs[@entity_id = $org_id]
	    let $org_dhis_uuid := ($org/csd:otherID[@assigningAuthorityName=concat($dhis_url,"/api/organisationUnit") and @code="uuid"])[1]
	    let $parent := 
	      if (functx:all-whitespace($org_id))
	      then ()  (: no parent :)
	      else if (not(functx:all-whitespace($org_dhis_uuid)))
	      then <dxf:parent id="{$org_dhis_uuid}"/>
	      else <dxf:parent id="{dxf2csd:extract_id_from_entityid(string($org_id))}"/>
	   return 
	     if (functx:all-whitespace($uuid) )
	     then ()
	     else
	       <dxf:organisationUnit 
                 level="{$level}"
		 name="{$name}"
		 shortName="{substring($name,1,50)}"
		 uuid="{$uuid}" 
		 id="{$id}" 
		 lastUpdated="{$lm}"
		 created="{$created}"
		 >
		 {$parent}
		 <dxf:openingDate>1970-01-01</dxf:openingDate> 
	       </dxf:organisationUnit>
	   }
      </dxf:organisationUnits>


      <dxf:organisationUnitGroups>
        { 
	  for $org_unit_group in $org_unit_groups
	  let $code := string($org_unit_group/@code)
	  let $scheme := string($org_unit_group/@codeSystem)
	  let $name := string($org_unit_group/@name)
	  let $short_name := substring(string($org_unit_group/@name),1,50)
	    return 
	    <dxf:organisationUnitGroup code="{$code}" name="{$name}" shortName="{$short_name}">
	      <dxf:organisationUnits>
		{
		  for $fac in $facilities[./csd:codedType[@codingScheme = $scheme and @code = $code]]
		  let $uuid := dxf2csd:extract_uuid_from_entityid($fac/@entityID)
		  let $fac_name := $fac/csd:primaryName/text()
		  let $id := string($fac/@entityID)
		  return     
		     <dxf:organisationUnit uuid="{$uuid}" id="{$id}" name="{$fac_name}" />
		}
	      </dxf:organisationUnits>
	    </dxf:organisationUnitGroup>
	}
      </dxf:organisationUnitGroups>

      { 
      if (count($org_unit_groups) > 0)
      then
        <dxf:organisationUnitGroupSets>
	  <dxf:organisationUnitGroupSet name='Facility Type'>
	    <dxf:description>Facility Type</dxf:description>
	    <dxf:compulsory>true</dxf:compulsory>
	    <dxf:dataDimension>true</dxf:dataDimension>
	    <dxf:organisationUnitGroups>
	      {
		for $org_unit_group in $org_unit_groups
		let $code := string($org_unit_group/@code)
		let $scheme := string($org_unit_group/@codeSystem)
		let $name := string($org_unit_group/@name)
		return   <dxf:organisationUnitGroup code="{$code}" name="{$name}" />
	      }
	    </dxf:organisationUnitGroups>
	  </dxf:organisationUnitGroupSet>	
	</dxf:organisationUnitGroupSets>
      else () 
      }

    </dxf:metaData>