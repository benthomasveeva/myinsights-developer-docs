ds.getSFDCSessionID()
    .then((resp) => {
        console.log(resp);
        return ds.request({
            url: resp.data.instanceUrl + "/api/v24.1/objects/users/me",
            headers: {
                "Authorization": resp.data.sessionId
            }
        });
    })
    .then((resp2) => {
        console.log(resp2.data.body);
        console.log(resp2);
    })
    .catch(console.warn);
