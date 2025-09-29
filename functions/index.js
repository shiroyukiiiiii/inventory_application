/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

// ✅ Replace with your email and app password
const transporter = nodemailer.createTransporter({
  service: "gmail",
  auth: {
    user: "your_email@gmail.com",
    pass: "your_app_password",  // App Password (NOT your normal Gmail password)
  },
});

// ✅ Cloud Function callable from Flutter
exports.sendUniformRequestEmail = functions.https.onCall(async (data, context) => {
  // Check authentication (only logged-in users can trigger)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to send an email."
    );
  }

  const mailOptions = {
    from: "your_email@gmail.com",
    to: data.to, // student's email
    subject: "Uniform Request Submitted",
    text: `Hello ${data.name || "Student"},

Your uniform request has been received!

Details:
Gender: ${data.gender}
Course: ${data.course}
Size: ${data.size}

Thank you for your request.

- SIASU Team
`
  };

  // Send the email
  await transporter.sendMail(mailOptions);
  return { success: true, message: "Email sent successfully!" };
});
