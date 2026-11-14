import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const projectId = 'demo-cherry-push-rules';
const protectedCollections = ['pushDevices', 'collectionPushJobs'];
const depths = ['', '/children/existing', '/children/existing/history/existing'];
const identities = ['anonymous', 'buyer'];
let environment;

before(async () => {
  // Refuse to run without an explicitly local emulator, even if credentials are
  // available in the developer's shell. No production Firebase project is used.
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8185');
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8185,
      rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8'),
    },
  });
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    for (const name of protectedCollections) {
      for (const suffix of depths) {
        await setDoc(doc(context.firestore(), `${name}/existing${suffix}`), {
          userId: 'buyer',
          token: 'emulator-only-token',
          status: 'pending',
          createdAt: '2026-01-01T00:00:00Z',
        });
      }
    }
  });
});

after(async () => {
  await environment?.cleanup();
});

function client(identity) {
  return identity === 'anonymous'
    ? environment.unauthenticatedContext().firestore()
    : environment.authenticatedContext(identity).firestore();
}

for (const identity of identities) {
  for (const name of protectedCollections) {
    for (const suffix of depths) {
      const path = `${name}/existing${suffix}`;
      const parentPath = path.slice(0, path.lastIndexOf('/'));
      const operations = {
        get: (db) => getDoc(doc(db, path)),
        list: (db) => getDocs(collection(db, parentPath)),
        create: (db) => setDoc(doc(db, `${parentPath}/new-${identity}`), {
          userId: identity,
          token: 'emulator-only-new-token',
          isAdmin: true,
        }),
        update: (db) => updateDoc(doc(db, path), {
          userId: 'attacker',
          status: 'sent',
          createdAt: -1,
          arbitraryField: ['invalid', 'state'],
        }),
        delete: (db) => deleteDoc(doc(db, path)),
      };
      for (const [operation, perform] of Object.entries(operations)) {
        test(`${identity} cannot ${operation} ${path}`, async () => {
          await assertFails(perform(client(identity)));
        });
      }
    }

    test(`${identity} cannot query the ${name} collection group`, async () => {
      await assertFails(getDocs(collectionGroup(client(identity), name)));
    });

    test(`${identity} cannot create or read an orphan descendant of ${name}`, async () => {
      const reference = doc(client(identity), `${name}/absent/children/new`);
      await assertFails(setDoc(reference, { userId: identity }));
      await assertFails(getDoc(reference));
    });
  }

  test(`${identity} cannot smuggle a protected write into a legacy batch`, async () => {
    const db = client(identity);
    const legacyPath = `legacyRulesProbe/rejected-batch-${identity}`;
    const batch = writeBatch(db);
    batch.set(doc(db, legacyPath), { message: 'must not be committed' });
    batch.set(doc(db, 'collectionPushJobs/forged-job'), { status: 'pending' });
    batch.set(doc(db, 'pushDevices/forged-device'), { token: 'forged' });
    await assertFails(batch.commit());
    await environment.withSecurityRulesDisabled(async (context) => {
      assert.equal((await getDoc(doc(context.firestore(), legacyPath))).exists(), false);
    });
  });

  test(`KNOWN LEGACY EXPOSURE: ${identity} retains unrelated read/write access`, async () => {
    const db = client(identity);
    const reference = doc(db, `legacyRulesProbe/${identity}`);
    await assertSucceeds(setDoc(reference, { arbitrary: true }));
    assert.equal((await assertSucceeds(getDoc(reference))).data().arbitrary, true);
    await assertSucceeds(getDocs(collection(db, 'legacyRulesProbe')));
    await assertSucceeds(updateDoc(reference, { arbitrary: 'unvalidated update' }));
    await assertSucceeds(deleteDoc(reference));
  });
}

for (const name of protectedCollections) {
  test(`client admin claims do not unlock ${name}`, async () => {
    const db = environment.authenticatedContext('claimed-admin', {
      admin: true,
      isAdmin: true,
      role: 'admin',
    }).firestore();
    await assertFails(getDoc(doc(db, `${name}/existing`)));
    await assertFails(setDoc(doc(db, `${name}/claimed-admin`), { userId: 'claimed-admin' }));
  });
}
