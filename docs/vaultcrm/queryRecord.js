let config = {
    object: 'account__v',
    fields: ['name__v', 'id'],
    where: "name__v != 'Matthew'",
    sort: ['name__v ASC'],
    limit: 10,
};
ds.queryRecord(config).then(console.log, console.warn);
