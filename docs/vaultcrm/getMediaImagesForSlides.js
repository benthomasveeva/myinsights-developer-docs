ds.queryRecord({object:"Key_Message_vod__c", fields:["Id"], limit: 2}).then((resp) => {
    let ids = resp.Key_Message_vod__c.map((km) => { return km.Id}); 
    return ds.getMediaImagesForSlides(ids);
}).then(console.log, console.warn);
