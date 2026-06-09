let config = {
  object: "account__v",
  fields: {
    id: "insert_account_id_here",
  },
};
ds.editRecord(config).then(console.log, console.warn);
