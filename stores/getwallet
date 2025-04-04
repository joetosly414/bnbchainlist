// bnbchainlist/utils/getWallet.js
import { Dispatcher } from 'flux';
import { EventEmitter } from 'events';
import AccountStore from '../stores/accountStore'; // path relative to getWallet.js

const dispatcher = new Dispatcher();
const emitter = new EventEmitter();

const accountStore = new AccountStore(dispatcher, emitter);

dispatcher.dispatch({
  type: 'TRY_CONNECT_WALLET',
  payload: { /* any data needed */ }
});

const accountData = accountStore.getStore('account');
console.log('Account data:', accountData);
console.log('Wallet address:', accountData?.address);
