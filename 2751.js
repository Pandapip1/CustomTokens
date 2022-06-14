"use strict";(self.webpackChunkcustomtokens=self.webpackChunkcustomtokens||[]).push([[2751],{48670:function(e,r,t){var n=t(48764).Buffer,o=this&&this.__read||function(e,r){var t="function"==typeof Symbol&&e[Symbol.iterator];if(!t)return e;var n,o,f=t.call(e),i=[];try{for(;(void 0===r||r-- >0)&&!(n=f.next()).done;)i.push(n.value)}catch(e){o={error:e}}finally{try{n&&!n.done&&(t=f.return)&&t.call(f)}finally{if(o)throw o.error}}return i},f=this&&this.__importDefault||function(e){return e&&e.__esModule?e:{default:e}};Object.defineProperty(r,"__esModule",{value:!0}),r.isZeroAddress=r.zeroAddress=r.importPublic=r.privateToAddress=r.privateToPublic=r.publicToAddress=r.pubToAddress=r.isValidPublic=r.isValidPrivate=r.generateAddress2=r.generateAddress=r.isValidChecksumAddress=r.toChecksumAddress=r.isValidAddress=r.Account=void 0;var i=f(t(69282)),a=t(14538),u=t(95053),s=t(54846),c=t(56861),d=t(14651),l=t(45641),p=t(63746),h=t(2971),g=function(){function e(e,r,t,n){void 0===e&&(e=new a.BN(0)),void 0===r&&(r=new a.BN(0)),void 0===t&&(t=c.KECCAK256_RLP),void 0===n&&(n=c.KECCAK256_NULL),this.nonce=e,this.balance=r,this.stateRoot=t,this.codeHash=n,this._validate()}return e.fromAccountData=function(r){var t=r.nonce,n=r.balance,o=r.stateRoot,f=r.codeHash;return new e(t?new a.BN((0,d.toBuffer)(t)):void 0,n?new a.BN((0,d.toBuffer)(n)):void 0,o?(0,d.toBuffer)(o):void 0,f?(0,d.toBuffer)(f):void 0)},e.fromRlpSerializedAccount=function(e){var r=a.rlp.decode(e);if(!Array.isArray(r))throw new Error("Invalid serialized account input. Must be array");return this.fromValuesArray(r)},e.fromValuesArray=function(r){var t=o(r,4),n=t[0],f=t[1],i=t[2],u=t[3];return new e(new a.BN(n),new a.BN(f),i,u)},e.prototype._validate=function(){if(this.nonce.lt(new a.BN(0)))throw new Error("nonce must be greater than zero");if(this.balance.lt(new a.BN(0)))throw new Error("balance must be greater than zero");if(32!==this.stateRoot.length)throw new Error("stateRoot must have a length of 32");if(32!==this.codeHash.length)throw new Error("codeHash must have a length of 32")},e.prototype.raw=function(){return[(0,h.bnToUnpaddedBuffer)(this.nonce),(0,h.bnToUnpaddedBuffer)(this.balance),this.stateRoot,this.codeHash]},e.prototype.serialize=function(){return a.rlp.encode(this.raw())},e.prototype.isContract=function(){return!this.codeHash.equals(c.KECCAK256_NULL)},e.prototype.isEmpty=function(){return this.balance.isZero()&&this.nonce.isZero()&&this.codeHash.equals(c.KECCAK256_NULL)},e}();r.Account=g,r.isValidAddress=function(e){try{(0,p.assertIsString)(e)}catch(e){return!1}return/^0x[0-9a-fA-F]{40}$/.test(e)},r.toChecksumAddress=function(e,r){(0,p.assertIsHexString)(e);var t=(0,s.stripHexPrefix)(e).toLowerCase(),n="";r&&(n=(0,h.toType)(r,h.TypeOutput.BN).toString()+"0x");for(var o=(0,l.keccakFromString)(n+t).toString("hex"),f="0x",i=0;i<t.length;i++)parseInt(o[i],16)>=8?f+=t[i].toUpperCase():f+=t[i];return f},r.isValidChecksumAddress=function(e,t){return(0,r.isValidAddress)(e)&&(0,r.toChecksumAddress)(e,t)===e},r.generateAddress=function(e,r){(0,p.assertIsBuffer)(e),(0,p.assertIsBuffer)(r);var t=new a.BN(r);return t.isZero()?(0,l.rlphash)([e,null]).slice(-20):(0,l.rlphash)([e,n.from(t.toArray())]).slice(-20)},r.generateAddress2=function(e,r,t){return(0,p.assertIsBuffer)(e),(0,p.assertIsBuffer)(r),(0,p.assertIsBuffer)(t),(0,i.default)(20===e.length),(0,i.default)(32===r.length),(0,l.keccak256)(n.concat([n.from("ff","hex"),e,r,(0,l.keccak256)(t)])).slice(-20)},r.isValidPrivate=function(e){return(0,u.privateKeyVerify)(e)},r.isValidPublic=function(e,r){return void 0===r&&(r=!1),(0,p.assertIsBuffer)(e),64===e.length?(0,u.publicKeyVerify)(n.concat([n.from([4]),e])):!!r&&(0,u.publicKeyVerify)(e)},r.pubToAddress=function(e,r){return void 0===r&&(r=!1),(0,p.assertIsBuffer)(e),r&&64!==e.length&&(e=n.from((0,u.publicKeyConvert)(e,!1).slice(1))),(0,i.default)(64===e.length),(0,l.keccak)(e).slice(-20)},r.publicToAddress=r.pubToAddress,r.privateToPublic=function(e){return(0,p.assertIsBuffer)(e),n.from((0,u.publicKeyCreate)(e,!1)).slice(1)},r.privateToAddress=function(e){return(0,r.publicToAddress)((0,r.privateToPublic)(e))},r.importPublic=function(e){return(0,p.assertIsBuffer)(e),64!==e.length&&(e=n.from((0,u.publicKeyConvert)(e,!1).slice(1))),e},r.zeroAddress=function(){var e=(0,d.zeros)(20);return(0,d.bufferToHex)(e)},r.isZeroAddress=function(e){try{(0,p.assertIsString)(e)}catch(e){return!1}return(0,r.zeroAddress)()===e}},6871:function(e,r,t){var n=t(48764).Buffer,o=this&&this.__importDefault||function(e){return e&&e.__esModule?e:{default:e}};Object.defineProperty(r,"__esModule",{value:!0}),r.Address=void 0;var f=o(t(69282)),i=t(14538),a=t(14651),u=t(48670),s=function(){function e(e){(0,f.default)(20===e.length,"Invalid address length"),this.buf=e}return e.zero=function(){return new e((0,a.zeros)(20))},e.fromString=function(r){return(0,f.default)((0,u.isValidAddress)(r),"Invalid address"),new e((0,a.toBuffer)(r))},e.fromPublicKey=function(r){return(0,f.default)(n.isBuffer(r),"Public key should be Buffer"),new e((0,u.pubToAddress)(r))},e.fromPrivateKey=function(r){return(0,f.default)(n.isBuffer(r),"Private key should be Buffer"),new e((0,u.privateToAddress)(r))},e.generate=function(r,t){return(0,f.default)(i.BN.isBN(t)),new e((0,u.generateAddress)(r.buf,t.toArrayLike(n)))},e.generate2=function(r,t,o){return(0,f.default)(n.isBuffer(t)),(0,f.default)(n.isBuffer(o)),new e((0,u.generateAddress2)(r.buf,t,o))},e.prototype.equals=function(e){return this.buf.equals(e.buf)},e.prototype.isZero=function(){return this.equals(e.zero())},e.prototype.isPrecompileOrSystemAddress=function(){var e=new i.BN(this.buf),r=new i.BN(0),t=new i.BN("ffff","hex");return e.gte(r)&&e.lte(t)},e.prototype.toString=function(){return"0x"+this.buf.toString("hex")},e.prototype.toBuffer=function(){return n.from(this.buf)},e}();r.Address=s},14651:function(e,r,t){var n=t(48764).Buffer,o=this&&this.__values||function(e){var r="function"==typeof Symbol&&Symbol.iterator,t=r&&e[r],n=0;if(t)return t.call(e);if(e&&"number"==typeof e.length)return{next:function(){return e&&n>=e.length&&(e=void 0),{value:e&&e[n++],done:!e}}};throw new TypeError(r?"Object is not iterable.":"Symbol.iterator is not defined.")},f=this&&this.__read||function(e,r){var t="function"==typeof Symbol&&e[Symbol.iterator];if(!t)return e;var n,o,f=t.call(e),i=[];try{for(;(void 0===r||r-- >0)&&!(n=f.next()).done;)i.push(n.value)}catch(e){o={error:e}}finally{try{n&&!n.done&&(t=f.return)&&t.call(f)}finally{if(o)throw o.error}}return i};Object.defineProperty(r,"__esModule",{value:!0}),r.bufArrToArr=r.arrToBufArr=r.validateNoLeadingZeroes=r.baToJSON=r.toUtf8=r.addHexPrefix=r.toUnsigned=r.fromSigned=r.bufferToHex=r.bufferToInt=r.toBuffer=r.unpadHexString=r.unpadArray=r.unpadBuffer=r.setLengthRight=r.setLengthLeft=r.zeros=r.intToBuffer=r.intToHex=void 0;var i=t(14538),a=t(54846),u=t(63746);r.intToHex=function(e){if(!Number.isSafeInteger(e)||e<0)throw new Error("Received an invalid integer type: ".concat(e));return"0x".concat(e.toString(16))},r.intToBuffer=function(e){var t=(0,r.intToHex)(e);return n.from((0,a.padToEven)(t.slice(2)),"hex")},r.zeros=function(e){return n.allocUnsafe(e).fill(0)};var s=function(e,t,n){var o=(0,r.zeros)(t);return n?e.length<t?(e.copy(o),o):e.slice(0,t):e.length<t?(e.copy(o,t-e.length),o):e.slice(-t)};r.setLengthLeft=function(e,r){return(0,u.assertIsBuffer)(e),s(e,r,!1)},r.setLengthRight=function(e,r){return(0,u.assertIsBuffer)(e),s(e,r,!0)};var c=function(e){for(var r=e[0];e.length>0&&"0"===r.toString();)r=(e=e.slice(1))[0];return e};r.unpadBuffer=function(e){return(0,u.assertIsBuffer)(e),c(e)},r.unpadArray=function(e){return(0,u.assertIsArray)(e),c(e)},r.unpadHexString=function(e){return(0,u.assertIsHexString)(e),e=(0,a.stripHexPrefix)(e),c(e)},r.toBuffer=function(e){if(null==e)return n.allocUnsafe(0);if(n.isBuffer(e))return n.from(e);if(Array.isArray(e)||e instanceof Uint8Array)return n.from(e);if("string"==typeof e){if(!(0,a.isHexString)(e))throw new Error("Cannot convert string to buffer. toBuffer only supports 0x-prefixed hex strings and this string was given: ".concat(e));return n.from((0,a.padToEven)((0,a.stripHexPrefix)(e)),"hex")}if("number"==typeof e)return(0,r.intToBuffer)(e);if(i.BN.isBN(e)){if(e.isNeg())throw new Error("Cannot convert negative BN to buffer. Given: ".concat(e));return e.toArrayLike(n)}if(e.toArray)return n.from(e.toArray());if(e.toBuffer)return n.from(e.toBuffer());throw new Error("invalid type")},r.bufferToInt=function(e){return new i.BN((0,r.toBuffer)(e)).toNumber()},r.bufferToHex=function(e){return"0x"+(e=(0,r.toBuffer)(e)).toString("hex")},r.fromSigned=function(e){return new i.BN(e).fromTwos(256)},r.toUnsigned=function(e){return n.from(e.toTwos(256).toArray())},r.addHexPrefix=function(e){return"string"!=typeof e||(0,a.isHexPrefixed)(e)?e:"0x"+e},r.toUtf8=function(e){if((e=(0,a.stripHexPrefix)(e)).length%2!=0)throw new Error("Invalid non-even hex string input for toUtf8() provided");return n.from(e.replace(/^(00)+|(00)+$/g,""),"hex").toString("utf8")},r.baToJSON=function(e){if(n.isBuffer(e))return"0x".concat(e.toString("hex"));if(e instanceof Array){for(var t=[],o=0;o<e.length;o++)t.push((0,r.baToJSON)(e[o]));return t}},r.validateNoLeadingZeroes=function(e){var r,t;try{for(var n=o(Object.entries(e)),i=n.next();!i.done;i=n.next()){var a=f(i.value,2),u=a[0],s=a[1];if(void 0!==s&&s.length>0&&0===s[0])throw new Error("".concat(u," cannot have leading zeroes, received: ").concat(s.toString("hex")))}}catch(e){r={error:e}}finally{try{i&&!i.done&&(t=n.return)&&t.call(n)}finally{if(r)throw r.error}}},r.arrToBufArr=function e(r){return Array.isArray(r)?r.map((function(r){return e(r)})):n.from(r)},r.bufArrToArr=function e(r){return Array.isArray(r)?r.map((function(r){return e(r)})):Uint8Array.from(null!=r?r:[])}},56861:(e,r,t)=>{Object.defineProperty(r,"__esModule",{value:!0}),r.KECCAK256_RLP=r.KECCAK256_RLP_S=r.KECCAK256_RLP_ARRAY=r.KECCAK256_RLP_ARRAY_S=r.KECCAK256_NULL=r.KECCAK256_NULL_S=r.TWO_POW256=r.MAX_INTEGER=r.MAX_UINT64=void 0;var n=t(48764),o=t(14538);r.MAX_UINT64=new o.BN("ffffffffffffffff",16),r.MAX_INTEGER=new o.BN("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",16),r.TWO_POW256=new o.BN("10000000000000000000000000000000000000000000000000000000000000000",16),r.KECCAK256_NULL_S="c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",r.KECCAK256_NULL=n.Buffer.from(r.KECCAK256_NULL_S,"hex"),r.KECCAK256_RLP_ARRAY_S="1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",r.KECCAK256_RLP_ARRAY=n.Buffer.from(r.KECCAK256_RLP_ARRAY_S,"hex"),r.KECCAK256_RLP_S="56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",r.KECCAK256_RLP=n.Buffer.from(r.KECCAK256_RLP_S,"hex")},14538:function(e,r,t){var n=this&&this.__createBinding||(Object.create?function(e,r,t,n){void 0===n&&(n=t);var o=Object.getOwnPropertyDescriptor(r,t);o&&!("get"in o?!r.__esModule:o.writable||o.configurable)||(o={enumerable:!0,get:function(){return r[t]}}),Object.defineProperty(e,n,o)}:function(e,r,t,n){void 0===n&&(n=t),e[n]=r[t]}),o=this&&this.__setModuleDefault||(Object.create?function(e,r){Object.defineProperty(e,"default",{enumerable:!0,value:r})}:function(e,r){e.default=r}),f=this&&this.__importStar||function(e){if(e&&e.__esModule)return e;var r={};if(null!=e)for(var t in e)"default"!==t&&Object.prototype.hasOwnProperty.call(e,t)&&n(r,e,t);return o(r,e),r},i=this&&this.__importDefault||function(e){return e&&e.__esModule?e:{default:e}};Object.defineProperty(r,"__esModule",{value:!0}),r.rlp=r.BN=void 0;var a=i(t(13550));r.BN=a.default;var u=f(t(51675));r.rlp=u},45641:(e,r,t)=>{var n=t(48764).Buffer;Object.defineProperty(r,"__esModule",{value:!0}),r.rlphash=r.ripemd160FromArray=r.ripemd160FromString=r.ripemd160=r.sha256FromArray=r.sha256FromString=r.sha256=r.keccakFromArray=r.keccakFromHexString=r.keccakFromString=r.keccak256=r.keccak=void 0;var o=t(82192),f=t(23482),i=t(14538),a=t(14651),u=t(63746);r.keccak=function(e,r){switch(void 0===r&&(r=256),(0,u.assertIsBuffer)(e),r){case 224:return(0,o.keccak224)(e);case 256:return(0,o.keccak256)(e);case 384:return(0,o.keccak384)(e);case 512:return(0,o.keccak512)(e);default:throw new Error("Invald algorithm: keccak".concat(r))}},r.keccak256=function(e){return(0,r.keccak)(e)},r.keccakFromString=function(e,t){void 0===t&&(t=256),(0,u.assertIsString)(e);var o=n.from(e,"utf8");return(0,r.keccak)(o,t)},r.keccakFromHexString=function(e,t){return void 0===t&&(t=256),(0,u.assertIsHexString)(e),(0,r.keccak)((0,a.toBuffer)(e),t)},r.keccakFromArray=function(e,t){return void 0===t&&(t=256),(0,u.assertIsArray)(e),(0,r.keccak)((0,a.toBuffer)(e),t)};var s=function(e){return e=(0,a.toBuffer)(e),f("sha256").update(e).digest()};r.sha256=function(e){return(0,u.assertIsBuffer)(e),s(e)},r.sha256FromString=function(e){return(0,u.assertIsString)(e),s(e)},r.sha256FromArray=function(e){return(0,u.assertIsArray)(e),s(e)};var c=function(e,r){e=(0,a.toBuffer)(e);var t=f("rmd160").update(e).digest();return!0===r?(0,a.setLengthLeft)(t,32):t};r.ripemd160=function(e,r){return(0,u.assertIsBuffer)(e),c(e,r)},r.ripemd160FromString=function(e,r){return(0,u.assertIsString)(e),c(e,r)},r.ripemd160FromArray=function(e,r){return(0,u.assertIsArray)(e),c(e,r)},r.rlphash=function(e){return(0,r.keccak)(i.rlp.encode(e))}},63746:(e,r,t)=>{var n=t(48764).Buffer;Object.defineProperty(r,"__esModule",{value:!0}),r.assertIsString=r.assertIsArray=r.assertIsBuffer=r.assertIsHexString=void 0;var o=t(54846);r.assertIsHexString=function(e){if(!(0,o.isHexString)(e)){var r="This method only supports 0x-prefixed hex strings but input was: ".concat(e);throw new Error(r)}},r.assertIsBuffer=function(e){if(!n.isBuffer(e)){var r="This method only supports Buffer but input was: ".concat(e);throw new Error(r)}},r.assertIsArray=function(e){if(!Array.isArray(e)){var r="This method only supports number arrays but input was: ".concat(e);throw new Error(r)}},r.assertIsString=function(e){if("string"!=typeof e){var r="This method only supports strings but input was: ".concat(e);throw new Error(r)}}},22751:function(e,r,t){var n=this&&this.__createBinding||(Object.create?function(e,r,t,n){void 0===n&&(n=t);var o=Object.getOwnPropertyDescriptor(r,t);o&&!("get"in o?!r.__esModule:o.writable||o.configurable)||(o={enumerable:!0,get:function(){return r[t]}}),Object.defineProperty(e,n,o)}:function(e,r,t,n){void 0===n&&(n=t),e[n]=r[t]}),o=this&&this.__exportStar||function(e,r){for(var t in e)"default"===t||Object.prototype.hasOwnProperty.call(r,t)||n(r,e,t)};Object.defineProperty(r,"__esModule",{value:!0}),r.isHexString=r.getKeys=r.fromAscii=r.fromUtf8=r.toAscii=r.arrayContainsArray=r.getBinarySize=r.padToEven=r.stripHexPrefix=r.isHexPrefixed=void 0,o(t(56861),r),o(t(48670),r),o(t(6871),r),o(t(45641),r),o(t(77112),r),o(t(14651),r),o(t(80867),r),o(t(14538),r),o(t(2971),r);var f=t(54846);Object.defineProperty(r,"isHexPrefixed",{enumerable:!0,get:function(){return f.isHexPrefixed}}),Object.defineProperty(r,"stripHexPrefix",{enumerable:!0,get:function(){return f.stripHexPrefix}}),Object.defineProperty(r,"padToEven",{enumerable:!0,get:function(){return f.padToEven}}),Object.defineProperty(r,"getBinarySize",{enumerable:!0,get:function(){return f.getBinarySize}}),Object.defineProperty(r,"arrayContainsArray",{enumerable:!0,get:function(){return f.arrayContainsArray}}),Object.defineProperty(r,"toAscii",{enumerable:!0,get:function(){return f.toAscii}}),Object.defineProperty(r,"fromUtf8",{enumerable:!0,get:function(){return f.fromUtf8}}),Object.defineProperty(r,"fromAscii",{enumerable:!0,get:function(){return f.fromAscii}}),Object.defineProperty(r,"getKeys",{enumerable:!0,get:function(){return f.getKeys}}),Object.defineProperty(r,"isHexString",{enumerable:!0,get:function(){return f.isHexString}})},54846:(e,r,t)=>{var n=t(48764).Buffer;function o(e){if("string"!=typeof e)throw new Error("[isHexPrefixed] input must be type 'string', received type ".concat(typeof e));return"0"===e[0]&&"x"===e[1]}function f(e){var r=e;if("string"!=typeof r)throw new Error("[padToEven] value must be type 'string', received ".concat(typeof r));return r.length%2&&(r="0".concat(r)),r}Object.defineProperty(r,"__esModule",{value:!0}),r.isHexString=r.getKeys=r.fromAscii=r.fromUtf8=r.toAscii=r.arrayContainsArray=r.getBinarySize=r.padToEven=r.stripHexPrefix=r.isHexPrefixed=void 0,r.isHexPrefixed=o,r.stripHexPrefix=function(e){if("string"!=typeof e)throw new Error("[stripHexPrefix] input must be type 'string', received ".concat(typeof e));return o(e)?e.slice(2):e},r.padToEven=f,r.getBinarySize=function(e){if("string"!=typeof e)throw new Error("[getBinarySize] method requires input type 'string', recieved ".concat(typeof e));return n.byteLength(e,"utf8")},r.arrayContainsArray=function(e,r,t){if(!0!==Array.isArray(e))throw new Error("[arrayContainsArray] method requires input 'superset' to be an array, got type '".concat(typeof e,"'"));if(!0!==Array.isArray(r))throw new Error("[arrayContainsArray] method requires input 'subset' to be an array, got type '".concat(typeof r,"'"));return r[t?"some":"every"]((function(r){return e.indexOf(r)>=0}))},r.toAscii=function(e){var r="",t=0,n=e.length;for("0x"===e.substring(0,2)&&(t=2);t<n;t+=2){var o=parseInt(e.substr(t,2),16);r+=String.fromCharCode(o)}return r},r.fromUtf8=function(e){var r=n.from(e,"utf8");return"0x".concat(f(r.toString("hex")).replace(/^0+|0+$/g,""))},r.fromAscii=function(e){for(var r="",t=0;t<e.length;t++){var n=e.charCodeAt(t).toString(16);r+=n.length<2?"0".concat(n):n}return"0x".concat(r)},r.getKeys=function(e,r,t){if(!Array.isArray(e))throw new Error("[getKeys] method expects input 'params' to be an array, got ".concat(typeof e));if("string"!=typeof r)throw new Error("[getKeys] method expects input 'key' to be type 'string', got ".concat(typeof e));for(var n=[],o=0;o<e.length;o++){var f=e[o][r];if(t&&!f)f="";else if("string"!=typeof f)throw new Error("invalid abi - expected type 'string', received ".concat(typeof f));n.push(f)}return n},r.isHexString=function(e,r){return!("string"!=typeof e||!e.match(/^0x[0-9A-Fa-f]*$/)||r&&e.length!==2+2*r)}},80867:function(e,r,t){var n=t(48764).Buffer,o=this&&this.__importDefault||function(e){return e&&e.__esModule?e:{default:e}};Object.defineProperty(r,"__esModule",{value:!0}),r.defineProperties=void 0;var f=o(t(69282)),i=t(54846),a=t(14538),u=t(14651);r.defineProperties=function(e,r,t){if(e.raw=[],e._fields=[],e.toJSON=function(r){if(void 0===r&&(r=!1),r){var t={};return e._fields.forEach((function(r){t[r]="0x".concat(e[r].toString("hex"))})),t}return(0,u.baToJSON)(e.raw)},e.serialize=function(){return a.rlp.encode(e.raw)},r.forEach((function(r,t){function o(){return e.raw[t]}function i(o){"00"!==(o=(0,u.toBuffer)(o)).toString("hex")||r.allowZero||(o=n.allocUnsafe(0)),r.allowLess&&r.length?(o=(0,u.unpadBuffer)(o),(0,f.default)(r.length>=o.length,"The field ".concat(r.name," must not have more ").concat(r.length," bytes"))):r.allowZero&&0===o.length||!r.length||(0,f.default)(r.length===o.length,"The field ".concat(r.name," must have byte length of ").concat(r.length)),e.raw[t]=o}e._fields.push(r.name),Object.defineProperty(e,r.name,{enumerable:!0,configurable:!0,get:o,set:i}),r.default&&(e[r.name]=r.default),r.alias&&Object.defineProperty(e,r.alias,{enumerable:!1,configurable:!0,set:i,get:o})})),t)if("string"==typeof t&&(t=n.from((0,i.stripHexPrefix)(t),"hex")),n.isBuffer(t)&&(t=a.rlp.decode(t)),Array.isArray(t)){if(t.length>e._fields.length)throw new Error("wrong number of fields in data");t.forEach((function(r,t){e[e._fields[t]]=(0,u.toBuffer)(r)}))}else{if("object"!=typeof t)throw new Error("invalid data");var o=Object.keys(t);r.forEach((function(r){-1!==o.indexOf(r.name)&&(e[r.name]=t[r.name]),-1!==o.indexOf(r.alias)&&(e[r.alias]=t[r.alias])}))}}},77112:(e,r,t)=>{var n=t(48764).Buffer;Object.defineProperty(r,"__esModule",{value:!0}),r.hashPersonalMessage=r.isValidSignature=r.fromRpcSig=r.toCompactSig=r.toRpcSig=r.ecrecover=r.ecsign=void 0;var o=t(95053),f=t(14538),i=t(14651),a=t(45641),u=t(63746),s=t(2971);function c(e,r){var t=(0,s.toType)(e,s.TypeOutput.BN);if(t.eqn(0)||t.eqn(1))return(0,s.toType)(e,s.TypeOutput.BN);if(!r)return t.subn(27);var n=(0,s.toType)(r,s.TypeOutput.BN);return t.sub(n.muln(2).addn(35))}function d(e){var r=new f.BN(e);return r.eqn(0)||r.eqn(1)}r.ecsign=function(e,r,t){var f=(0,o.ecdsaSign)(e,r),i=f.signature,a=f.recid,u=n.from(i.slice(0,32)),c=n.from(i.slice(32,64));if(!t||"number"==typeof t){if(t&&!Number.isSafeInteger(t))throw new Error("The provided number is greater than MAX_SAFE_INTEGER (please use an alternative input type)");return{r:u,s:c,v:t?a+(2*t+35):a+27}}return{r:u,s:c,v:(0,s.toType)(t,s.TypeOutput.BN).muln(2).addn(35).addn(a).toArrayLike(n)}},r.ecrecover=function(e,r,t,f,a){var u=n.concat([(0,i.setLengthLeft)(t,32),(0,i.setLengthLeft)(f,32)],64),s=c(r,a);if(!d(s))throw new Error("Invalid signature v value");var l=(0,o.ecdsaRecover)(u,s.toNumber(),e);return n.from((0,o.publicKeyConvert)(l,!1).slice(1))},r.toRpcSig=function(e,r,t,o){if(!d(c(e,o)))throw new Error("Invalid signature v value");return(0,i.bufferToHex)(n.concat([(0,i.setLengthLeft)(r,32),(0,i.setLengthLeft)(t,32),(0,i.toBuffer)(e)]))},r.toCompactSig=function(e,r,t,o){if(!d(c(e,o)))throw new Error("Invalid signature v value");var f=(0,s.toType)(e,s.TypeOutput.Number),a=t;return(f>28&&f%2==1||1===f||28===f)&&((a=n.from(t))[0]|=128),(0,i.bufferToHex)(n.concat([(0,i.setLengthLeft)(r,32),(0,i.setLengthLeft)(a,32)]))},r.fromRpcSig=function(e){var r,t,n,o=(0,i.toBuffer)(e);if(o.length>=65)r=o.slice(0,32),t=o.slice(32,64),n=(0,i.bufferToInt)(o.slice(64));else{if(64!==o.length)throw new Error("Invalid signature length");r=o.slice(0,32),t=o.slice(32,64),n=(0,i.bufferToInt)(o.slice(32,33))>>7,t[0]&=127}return n<27&&(n+=27),{v:n,r,s:t}},r.isValidSignature=function(e,r,t,n,o){void 0===n&&(n=!0);var i=new f.BN("7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0",16),a=new f.BN("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",16);if(32!==r.length||32!==t.length)return!1;if(!d(c(e,o)))return!1;var u=new f.BN(r),s=new f.BN(t);return!(u.isZero()||u.gt(a)||s.isZero()||s.gt(a)||n&&1===s.cmp(i))},r.hashPersonalMessage=function(e){(0,u.assertIsBuffer)(e);var r=n.from("Ethereum Signed Message:\n".concat(e.length),"utf-8");return(0,a.keccak)(n.concat([r,e]))}},2971:(e,r,t)=>{var n=t(48764).Buffer;Object.defineProperty(r,"__esModule",{value:!0}),r.toType=r.TypeOutput=r.bnToRlp=r.bnToUnpaddedBuffer=r.bnToHex=void 0;var o,f=t(14538),i=t(54846),a=t(14651);function u(e){return(0,a.unpadBuffer)(e.toArrayLike(n))}r.bnToHex=function(e){return"0x".concat(e.toString(16))},r.bnToUnpaddedBuffer=u,r.bnToRlp=function(e){return u(e)},function(e){e[e.Number=0]="Number",e[e.BN=1]="BN",e[e.Buffer=2]="Buffer",e[e.PrefixedHexString=3]="PrefixedHexString"}(o=r.TypeOutput||(r.TypeOutput={})),r.toType=function(e,r){if(null===e)return null;if(void 0!==e){if("string"==typeof e&&!(0,i.isHexString)(e))throw new Error("A string must be provided with a 0x-prefix, given: ".concat(e));if("number"==typeof e&&!Number.isSafeInteger(e))throw new Error("The provided number is greater than MAX_SAFE_INTEGER (please use an alternative input type)");var t=(0,a.toBuffer)(e);if(r===o.Buffer)return t;if(r===o.BN)return new f.BN(t);if(r===o.Number){var n=new f.BN(t),u=new f.BN(Number.MAX_SAFE_INTEGER.toString());if(n.gt(u))throw new Error("The provided number is greater than MAX_SAFE_INTEGER (please use an alternative output type)");return n.toNumber()}return"0x".concat(t.toString("hex"))}}}}]);