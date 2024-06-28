ds.queryRecord({object:"CLM_Presentation_vod__c", fields:["Id"], limit: 2}).then((resp) => {
    let ids = resp.CLM_Presentation_vod__c.map((pres) => { return pres.Id}); 
    return ds.getFirstSlideForPresentations(ids);
}).then(console.log, console.warn);
