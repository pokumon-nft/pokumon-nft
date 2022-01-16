import * as firebase from "firebase-admin";
import serviceAccount from "../firestore-service-account.json";

const params = {
  type: serviceAccount.type,
  projectId: serviceAccount.project_id,
  privateKeyId: serviceAccount.private_key_id,
  privateKey: serviceAccount.private_key,
  clientEmail: serviceAccount.client_email,
  clientId: serviceAccount.client_id,
  authUri: serviceAccount.auth_uri,
  tokenUri: serviceAccount.token_uri,
  authProviderX509CertUrl: serviceAccount.auth_provider_x509_cert_url,
  clientC509CertUrl: serviceAccount.client_x509_cert_url,
};

export class Firebase {
  private static instance: Firebase;
  db: firebase.firestore.Firestore;

  private constructor() {
    firebase.initializeApp({
      credential: firebase.credential.cert(params),
    });
    this.db = firebase.firestore();
  }

  static getInstance() {
    if (!Firebase.instance) {
      Firebase.instance = new Firebase();
    }
    return Firebase.instance;
  }

  async addNFT(
    imageUrl: string,
    name: string,
    tokenId: number,
    tokenUri: string
  ) {
    this.db.collection("pokumons").add({
      image_url: imageUrl,
      name: name,
      token_id: tokenId,
      token_uri: tokenUri,
      is_sold: false,
    });
  }
}
