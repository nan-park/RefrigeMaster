const functions = require("firebase-functions");
const admin = require("firebase-admin");

var serviceAccount = require("./refrigemaster-firebase-adminsdk-6ci9t-a95660ac35.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
exports.createCustomToken = functions.region("asia-northeast2").https.onRequest(async (request, response) => {
    const user = request.body;

    const uid = "kakao:" + user.uid;
    const updateParams = {
        photoURL: user.photoURL,
        displayName: user.displayName,
        email: user.email
    };

    try {
        await admin.auth().updateUser(uid, updateParams);
        console.log("updateuser")
    } catch (e) {
        updateParams["uid"] = uid;
        await admin.auth().createUser(updateParams);
        console.log("createuser")
    }

    const token = await admin.auth().createCustomToken(uid);

    response.send(token);
});
