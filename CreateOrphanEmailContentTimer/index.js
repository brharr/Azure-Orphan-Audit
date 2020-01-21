const { QueueServiceClient, StorageSharedKeyCredential } = require("@azure/storage-queue");

module.exports = async function (context, myTimer) {
    const account = "azureorphanaudits";
    const accountKey = process.env.ACCOUNT_KEY || "H1hFVL4ZipGE7gspGhnrFETglQNhEiq6lvahKrD2Ytez4VJOWbHzhldw/U4TyhiuxkNDFuL+enfZZCLnU+Tl1Q==";
    const queueName = process.env.QUEUE_NAME || "orphans";
    const reportName = process.env.REPORT_NAME || "auditreports"
    
    // Use StorageSharedKeyCredential with storage account and account key
    // StorageSharedKeyCredential is only avaiable in Node.js runtime, not in browsers
    const sharedKeyCredential = new StorageSharedKeyCredential(account, accountKey);

    const queueServiceClient = new QueueServiceClient(`https://${account}.queue.core.windows.net`, sharedKeyCredential );
    const queueClient = queueServiceClient.getQueueClient(queueName);
    const reportClient = queueServiceClient.getQueueClient(reportName);

    let options = { "numberOfMessages": 32 };
    let orphanReport = "";

    do {
        const dequeueResponse = await queueClient.receiveMessages(options);
        for (var i = 0; i < dequeueResponse.receivedMessageItems.length; i++) {
            const dequeueMessageItem = dequeueResponse.receivedMessageItems[i];

            // Azure Functions automatically encodes new queue messages, so we have to decode before we can actaully do anything with the message
            const data = dequeueMessageItem.messageText;
            let message = Buffer.from(data, 'base64').toString('utf8');
            console.log(`Processing & deleting message with content: ${message}`);

            orphanReport = orphanReport.concat(message);
            orphanReport = orphanReport.concat('\n');
            const deleteMessageResponse = await queueClient.deleteMessage(
                dequeueMessageItem.messageId,
                dequeueMessageItem.popReceipt
            );
            console.log(
                `Delete message succesfully, service assigned request Id: ${deleteMessageResponse.requestId}`
            );
        }
    } while ((await queueClient.receiveMessages(options)).receivedMessageItems.length > 0)

    context.bindings.outputQueueItem = 
    await reportClient.sendMessage(orphanReport);
    console.log("Final Report: " + orphanReport); 
};