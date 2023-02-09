// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021-2023 Dyne.org foundation <foundation@dyne.org>.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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