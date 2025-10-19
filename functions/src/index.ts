import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

admin.initializeApp();

const gmailEmail = "ninipiegaming.karl@gmail.com";
const gmailPassword = "wand kjvx gzkh hsmd"; // ⚠️ Use your Google App Password, not your Gmail password

const mailTransport = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: gmailEmail,
    pass: gmailPassword,
  },
});

// This function automatically triggers when a uniform document is updated
export const sendLowStockAlert = functions.firestore
  .document("uniforms/{uniformId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!after || after.quantity === undefined) return null;

    const lowStockThreshold = 5;

    // Only trigger if stock dropped below the threshold
    if (before.quantity > lowStockThreshold && after.quantity <= lowStockThreshold) {
      const mailOptions = {
        from: `"SIASU Inventory" <${gmailEmail}>`,
        to: "ninipiegaming@gmail.com", // change to your admin email(s)
        subject: "⚠️ Low Stock Alert",
        text: `Hello Admin,

The stock for the following uniform is low:

Course: ${after.course}
Gender: ${after.gender}
Size: ${after.size}
Remaining Quantity: ${after.quantity}

Please restock soon.

— SIASU Inventory System`,
      };

      try {
        await mailTransport.sendMail(mailOptions);
        console.log("Low stock alert sent successfully.");
      } catch (error) {
        console.error("Error sending email:", error);
      }
    }

    return null;
  });
