import { readFileSync, writeFileSync} from 'fs';
import { join } from 'path';

import keypairoomClient from "../zenflows-crypto/src/keypairoomClient-8-9-10-11-12";
import sign from "../zenflows-crypto/src/sign_graphql";
import keypairoomClientRecreateKeys from "../zenflows-crypto/src/keypairoomClientRecreateKeys";
import signFile from "../zenflows-crypto/src/sign_file";


writeFileSync(join(__dirname, "keypairoomClient.zen"), keypairoomClient, {
    flag: 'w',
  });

writeFileSync(join(__dirname, "sign.zen"), sign(), {
    flag: 'w',
  });

writeFileSync(join(__dirname, "keypairoomClientRecreateKeys.zen"), keypairoomClientRecreateKeys, {
    flag: 'w',
  });

writeFileSync(join(__dirname, "signFile.zen"), signFile(), {
    flag: 'w',
  });

// console.log(keypairoomClient);