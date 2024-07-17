ds.queryRecord({object:"clm_presentation__v", fields:["id"], limit: 2}).then((resp) => {
    let ids = resp.CLM_Presentation_vod__c.map((pres) => { return pres.id}); 
    return ds.getFirstSlideForPresentations(ids);
}).then(console.log, console.warn);
