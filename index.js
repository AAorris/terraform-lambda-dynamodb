/** A lambda that does some placeholder work with DynamoDB */

const aws = require("aws-sdk");

const db = new aws.DynamoDB.DocumentClient();
const TableName = "sandbox";

function put(key, value) {
  return db.put({ TableName, Item: { key, value } }).promise();
}

function getAll() {
  return db.scan({ TableName }).promise();
}

exports.handler = async function (event, context, callback) {
  await put("testing", new Date().getTime());
  const items = await getAll();
  callback(null, {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
    },
    body: JSON.stringify({ count: items.Count }),
  });
};
