module.exports = async function (context, req) {
    context.log('JavaScript HTTP trigger function processed a request.');

    if (req.body) {
        context.log('Orphan Found: ' + req.body)
        context.bindings.outputQueueItem = JSON.stringify(req.body)
    }
    else {
        context.res = {
            status: 400,
            body: "The following body content was found:" + req.body
        };
    }
};