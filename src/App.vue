<script setup>
import { ref } from 'vue';
import Onboard from '@web3-onboard/core';
import { ContractFactory, providers } from 'ethers';
import 'bootstrap';

// Onboard modules
import injectedModule from '@web3-onboard/injected-wallets';

const token = ref({
    meta: {
        name: "",
        symbol: ""
    },
    redist: {
        holder: 0,
        addresses: [],
        fee: 0,
        supdev: true,
        temp: {
            amt: 0,
            addr: ""
        }
    },
    supply: [],
    tempSupply: {
        amt: 0,
        addr: ""
    },
    deployment: {
        tx: "",
        contract: ""
    },
});
const deploymentStep = ref(0);

const onboard = Onboard({
    wallets: [
        injectedModule(),
    ],
    chains: [
        {
            id: '0x1',
            token: 'ETH',
            label: 'Ethereum Mainnet',
            rpcUrl: 'https://rpc.flashbots.net/' // Free mainnet RPC + protection against Front Running
        },
        {
            id: '0xA',
            token: 'ETH',
            label: 'Optimism on Ethereum',
            rpcUrl: 'https://optimism-mainnet.public.blastapi.io/'
        },
        {
            id: '0x89',
            token: 'MATIC',
            label: 'Polygon',
            rpcUrl: 'https://rpc-mainnet.matic.network/'
        },
        {
            id: '0x38',
            token: 'BNB',
            label: 'Binance Smart Chain',
            rpcUrl: 'https://bsc-dataseed3.binance.org/'
        },
        {
            id: '0x64',
            token: 'xDAI',
            label: 'Gnosis Chain Mainnet',
            rpcUrl: 'wss://rpc.gnosischain.com/wss'
        },
        {
            id: '0x3',
            token: 'tROP',
            label: 'Ethereum Ropsten Testnet',
            rpcUrl: 'https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161' // RPC from rpc.info
        },
        {
            id: '0x4',
            token: 'rETH',
            label: 'Ethereum Rinkeby Testnet',
            rpcUrl: 'https://rinkeby-light.eth.linkpool.io/'
        },
    ],
    appMetadata: {
    name: 'Create ER20 Token (by Pandapip1)',
    icon: './img/Rocket-transparent.png',
    description: 'Create your own custom ERC20 token',
        recommendedInjectedWallets: [
            { name: 'MetaMask', url: 'https://metamask.io' },
            { name: 'Coinbase', url: 'https://wallet.coinbase.com/' }
        ]
    },
});

// Forwarders config
const forwarders = {
    1: [ '0xAa3E82b4c4093b4bA13Cb5714382C99ADBf750cA', ],
    10: [ '0x67097a676FCb14dc0Ff337D0D1F564649aD94715', ],
    137: [ '0xdA78a11FD57aF7be2eDD804840eA7f4c2A38801d', ],
    56: [ '0xeB230bF62267E94e657b5cbE74bdcea78EB3a5AB', ],
    100: [ '0x7eEae829DF28F9Ce522274D5771A6Be91d00E5ED', ],
    3: [ '0xeB230bF62267E94e657b5cbE74bdcea78EB3a5AB', ],
    4: [ '0x83A54884bE4657706785D7309cf46B58FE5f6e8a', ],
    42: [ '0x7eEae829DF28F9Ce522274D5771A6Be91d00E5ED', ],
}

const txExplorerUrls = {
    1: 'https://etherscan.io/tx/',
    10: 'https://optimistic.etherscan.io/tx/',
    137: 'https://polygonscan.io/tx/',
    56: 'https://bscscan.com/tx/',
    100: 'https://blockscout.com/tx/',
    3: 'https://ropsten.etherscan.io/tx/',
    4: 'https://rinkeby.etherscan.io/tx/',
    42: 'https://kovan.etherscan.io/tx/'
};

const contractTrackerUrls = {
    1: 'https://etherscan.io/tx/',
    10: 'https://optimistic.etherscan.io/tx/',
    137: 'https://polygonscan.io/tx/',
    56: 'https://bscscan.com/tx/',
    100: 'https://blockscout.com/tx/',
    3: 'https://ropsten.etherscan.io/tx/',
    4: 'https://rinkeby.etherscan.io/tx/',
    42: 'https://kovan.etherscan.io/tx/'
};

const contractVerificationAPIs = {
    1: 'https://etherscan.io/tx/',
    10: 'https://optimistic.etherscan.io/tx/',
    137: 'https://polygonscan.io/tx/',
    56: 'https://bscscan.com/tx/',
    100: 'https://blockscout.com/tx/',
    3: 'https://ropsten.etherscan.io/tx/',
    4: 'https://rinkeby.etherscan.io/tx/',
    42: 'https://kovan.etherscan.io/tx/'
};


async function deploy() {
    // Connect, trying cached wallet first
    deploymentStep.value++;
    const previouslyConnectedWallets = JSON.parse(window.localStorage.getItem('connectedWallets'));

    if (previouslyConnectedWallets) {
        await onboard.connectWallet({ autoSelect: { label: previouslyConnectedWallets[0], disableModals: true } });
    } else {
        await onboard.connectWallet();
    }

    // Cache selected wallet
    const walletsSub = onboard.state.select('wallets');
    const { unsubscribe } = walletsSub.subscribe(wallets => {
        window.localStorage.setItem(
            'connectedWallets',
            JSON.stringify(wallets.map(({ label }) => label))
        );
        unsubscribe();
    });

    // Get provider
    const [primaryWallet] = onboard.state.get().wallets;

    const provider = new providers.Web3Provider(primaryWallet.provider);
    const signer = provider.getSigner();

    // Fetch token bytecode & abi
    deploymentStep.value++;
    const [ bytecode, abi ] = await Promise.all([ // Parallel fetch
        fetch('./bin/bytecode/contracts_CustomERC20_sol_CustomERC20.bin').then(res => res.text),
        fetch('./bin/abi/contracts_CustomERC20_sol_CustomERC20.abi').then(res => res.json())
    ]);

    // Deploy token
    deploymentStep.value++;
    const factory = new ContractFactory(abi, bytecode, signer);

    const contract = await factory.deploy();
    const address = contract.address;
    token.value.deployment.tx = `${txExplorerUrls[await provider.getNetwork().then(({ chainId }) => chainId)]}${contract.deployTransaction.hash}`;

    // Wait for transaction to be mined
    deploymentStep.value++;
    await contract.deployTransaction.wait();

    // Set token metadata
    deploymentStep.value++;

    const validForwarders = forwarders[await provider.getNetwork().then(({ chainId }) => chainId)];

    const tx = await contract.multicall(await Promise.all([
        // Metadata
        contract.populateTransaction.setName(token.value.meta.name),
        contract.populateTransaction.setSymbol(token.value.meta.symbol),
        // Redistribution Properties
        contract.populateTransaction.setAmountTransferred(10 ** 18 - token.value.redist.fee * (10 ** 16)),
        contract.populateTransaction.setDistributionForHolders(token.value.redist.holder * token.value.redist.fee * (10 ** 14)),
        ...token.value.redist.addresses.map(({ addr, amt }) => contract.populateTransaction.setDistributionForAddress(addr, amt * token.value.redist.fee * (10 ** 14))),
        // Initial Balances
        ...token.value.supply.map(({ addr, amt }) => contract.populateTransaction.setBalance(addr, amt * (10 ** 18))),
        // Meta TX
        ...validForwarders.map(forwarder => contract.populateTransaction.setForwarder(forwarder, true))
    ]));
    token.value.deployment.contract = `${txExplorerUrls[await provider.getNetwork().then(({ chainId }) => chainId)]}${tx.hash}`;

    // Wait for transaction to be mined
    deploymentStep.value++;
    await tx.wait();

    // Disconnect when done
    await onboard.disconnectWallet({ label: primaryWallet.label });

    // Verify on etherscan
    deploymentStep.value++;
    // TODO: Verify on etherscan

    // Show result
    deploymentStep.value++;
    token.value.deployment.contract = `${contractTrackerUrls[await provider.getNetwork().then(({ chainId }) => chainId)]}${address}`;
}
</script>

<template>
    <div style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);" class="w-75">
        <div class="card mb-3 w-100 h-100 bg-white text-dark p-3">
            <div class="col-md-auto text-black">
                <div class="d-flex align-items-start">
                    <div class="nav flex-column nav-pills me-3" id="v-pills-tab" role="tablist" aria-orientation="vertical">
                        <button class="nav-link active" id="v-pills-meta-tab" data-bs-toggle="pill" data-bs-target="#v-pills-meta" type="button" role="tab" aria-controls="v-pills-meta" aria-selected="true" v-bind:disabled="deploymentStep != 0" v-bind:class="{ disabled: deploymentStep != 0 }">Metadata</button>
                        <button class="nav-link" id="v-pills-redist-tab" data-bs-toggle="pill" data-bs-target="#v-pills-redist" type="button" role="tab" aria-controls="v-pills-redist" aria-selected="false" v-bind:disabled="!token.meta.symbol || !token.meta.name || deploymentStep != 0" v-bind:class="{ disabled: !token.meta.symbol || !token.meta.name || deploymentStep != 0 }">Redistribution</button>
                        <button class="nav-link" id="v-pills-supply-tab" data-bs-toggle="pill" data-bs-target="#v-pills-supply" type="button" role="tab" aria-controls="v-pills-supply" aria-selected="false" v-bind:disabled="!token.meta.symbol || !token.meta.name || deploymentStep != 0" v-bind:class="{ disabled: !token.meta.symbol || !token.meta.name || deploymentStep != 0 }">Initial Supply</button>
                        <button class="nav-link" id="v-pills-deploy-tab" data-bs-toggle="pill" data-bs-target="#v-pills-deploy" type="button" role="tab" aria-controls="v-pills-deploy" aria-selected="false" v-bind:disabled="!token.meta.symbol || !token.meta.name || !token.supply.length" v-bind:class="{ disabled: !token.meta.symbol || !token.meta.name || !token.supply.length }">Deploy</button>
                    </div>
                    <div class="tab-content w-100" id="v-pills-tabContent">
                        <div class="tab-pane fade show active" id="v-pills-meta" role="tabpanel" aria-labelledby="v-pills-meta-tab">
                            <div class="input-group">
                                <input type="text" aria-label="Name" class="form-control" placeholder="Name (e.g. My Epic Token)" v-model="token.meta.name">
                                <input type="text" aria-label="Symbol" class="form-control" placeholder="Symbol (e.g MYTOKEN)" v-model="token.meta.symbol">
                                <input type="text" aria-label="Decimals" class="form-control" readonly value="18">
                            </div>
                        </div>
                        <div class="tab-pane fade" id="v-pills-redist" role="tabpanel" aria-labelledby="v-pills-redist-tab">
                            <label for="feeRange" class="form-label">Fee: {{ token.redist.fee }}%</label>
                            <input type="range" class="form-range" min="0" max="15" step="0.5" id="feeRange" v-model="token.redist.fee">
                            <div v-if="token.redist.fee != 0">
                                <hr/>
                                <label for="burnRange" class="form-label">Burn: {{ 100 - token.redist.addresses.reduce((previousValue, item) => (previousValue + item.amt), 0) - token.redist.holder }}%</label>
                                <input type="range" class="form-range disabled" min="0" max="100" step="0.1" id="burnRange" v-bind:value="100 - token.redist.addresses.reduce((previousValue, item) => (previousValue + item.amt), 0) - token.redist.holder" disabled>
                                <label for="holdRange" class="form-label">Holder Redistribution: {{ token.redist.holder }}%</label>
                                <input type="range" class="form-range" min="0" max="100" step="0.1" id="holdRange" v-model="token.redist.holder" readonly>
                                <div class="container">
                                    <div class="row" v-for="(item, index) in token.redist.addresses" v-bind:key="item.addr">
                                        <div class="col" style="vertical-align: middle;">
                                            {{ token.redist.addresses[index].addr }}
                                        </div>
                                        <div class="col-md-auto" style="vertical-align: middle;">
                                            {{ token.redist.addresses[index].amt }}%
                                        </div>
                                        <div class="col-md-auto" style="vertical-align: middle;">
                                            <a href="#" v-on:click="token.redist.addresses.splice(index, 1)">Remove</a>
                                        </div>
                                    </div>
                                </div>
                                <div class="container">
                                    <div class="row">
                                        <div class="col-12">
                                            <div class="input-group">
                                                <input type="text" class="form-control" v-model="token.redist.temp.addr" placeholder="Ethereum Address (0x000...)">
                                                <input type="number" class="form-control" v-model="token.redist.temp.amt" placeholder="Redistribution Percent (e.g. 5)">
                                                <span class="input-group-text">%</span>
                                                <button class="btn btn-outline-primary" v-on:click="token.redist.addresses.push({ addr: token.redist.temp.addr, amt: token.redist.temp.amt })">Add</button>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="form-check" v-if="100 != token.redist.addresses.reduce((previousValue, item) => (previousValue + item.amt), 0) + token.redist.holder">
                                    <br/>
                                    <input class="form-check-input" type="checkbox" id="supportDev" v-model="token.redist.supdev">
                                    <label class="form-check-label" for="supportDev">
                                        Support <a href="https://github.com/Pandapip1" target="_blank">the developer</a> with 0.5% of the amount that would usually be burnt
                                    </label>
                                </div>
                            </div>
                        </div>
                        <div class="tab-pane fade" id="v-pills-supply" role="tabpanel" aria-labelledby="v-pills-supply-tab">
                            <div class="container">
                                <div class="row" v-for="(item, index) in token.supply" v-bind:key="item.addr">
                                    <div class="col" style="vertical-align: middle;">
                                        {{ token.supply[index].addr }}
                                    </div>
                                    <div class="col-md-auto" style="vertical-align: middle;">
                                        {{ token.supply[index].amt }} {{ token.meta.symbol }}
                                    </div>
                                    <div class="col-md-auto" style="vertical-align: middle;">
                                        <a href="#" v-on:click="token.supply.splice(index, 1)">Remove</a>
                                    </div>
                                </div>
                            </div>
                            <div class="input-group">
                                <input type="text" class="form-control" v-model="token.tempSupply.addr" placeholder="Ethereum Address (0x000...)">
                                <input type="number" class="form-control" v-model="token.tempSupply.amt" placeholder="Initial Supply (e.g. 100000)">
                                <span class="input-group-text">{{ token.meta.symbol }}</span>
                                <button class="btn btn-outline-primary" v-on:click="token.supply.push({ addr: token.tempSupply.addr, amt: token.tempSupply.amt })">Add</button>
                            </div>
                        </div>
                        <div class="tab-pane fade" id="v-pills-deploy" role="tabpanel" aria-labelledby="v-pills-deploy-tab">
                            <div v-if="deploymentStep == 0">
                                <div class="alert alert-warning" role="alert">
                                    <i class="bi bi-exclamation-circle"></i> Double-check all the information below before deploying. It can't be changed afterwards!
                                </div>
                                <hr/>
                                <div class="input-group mb-3">
                                    <span class="input-group-text" id="name-addon">Name</span>
                                    <input type="text" class="form-control" placeholder="Name" aria-label="Name" aria-describedby="name-addon" readonly v-model="token.meta.name">
                                </div>
                                <div class="input-group mb-3">
                                    <span class="input-group-text" id="symbol-addon">Symbol</span>
                                    <input type="text" class="form-control" placeholder="Symbol" aria-label="Symbol" aria-describedby="symbol-addon" readonly v-model="token.meta.symbol">
                                </div>
                                <hr/>
                                <div class="input-group mb-3">
                                    <span class="input-group-text" id="fee-addon">Fee</span>
                                    <input type="text" class="form-control" placeholder="Fee" aria-label="Fee" aria-describedby="fee-addon" readonly v-bind:value="`${token.redist.fee}%`">
                                </div>
                                <div class="input-group mb-3">
                                    <span class="input-group-text" id="burn-addon">Burned</span>
                                    <input type="text" class="form-control" placeholder="Burn" aria-label="Burn" aria-describedby="burn-addon" readonly v-bind:value="`${100 - token.redist.addresses.reduce((previousValue, item) => (previousValue + item.amt), 0) - token.redist.holder}%`">
                                </div>
                                <div v-if="token.redist.fee != 0 && deploymentStep == 0">
                                    <div class="input-group mb-3" v-for="(item, index) in token.redist.addresses" v-bind:key="item.addr">
                                        <span class="input-group-text" v-bind:id="`redist-addon${index}`">{{ item.addr }}</span>
                                        <input type="text" class="form-control" placeholder="Redist" aria-label="Redist" v-bind:aria-describedby="`redist-addon${index}`" readonly v-bind:value="`${item.amt}%`">
                                    </div>
                                </div>
                                <hr/>
                                <div class="input-group mb-3">
                                    <span class="input-group-text" id="isupply-addon">Initial Supply</span>
                                    <input type="text" class="form-control" placeholder="Initial Supply" aria-label="Initial Supply" aria-describedby="isupply-addon" readonly v-bind:value="`${token.supply.reduce((previousValue, item) => previousValue + item.amt, 0)} ${token.meta.symbol}`">
                                </div>
                                <div class="input-group mb-3" v-for="(item, index) in token.supply" v-bind:key="item.addr">
                                    <span class="input-group-text" v-bind:id="`redist-addon${index}`">{{ item.addr }}</span>
                                    <input type="text" class="form-control" placeholder="Redist" aria-label="Redist" v-bind:aria-describedby="`redist-addon${index}`" readonly v-bind:value="`${item.amt} ${token.meta.symbol}`">
                                </div>
                            <button v-on:click="deploy()" class="btn btn-primary w-100" type="button">
                                Deploy!
                            </button>
                            <hr/>
                            </div>
                            <div class="progress" v-if="deploymentStep != 0">
                                <div class="progress-bar" role="progressbar" v-bind:aria-valuenow="deploymentStep" v-bind:style="{ width: `${deploymentStep * 4}%` }" aria-valuemin="0" aria-valuemax="100"></div>
                            </div>
                            <button disabled class="btn btn-primary w-100 disabled" type="button" v-if="deploymentStep == 1">
                                <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                                Waiting on user approval...
                            </button>
                            <button disabled class="btn btn-primary w-100 disabled" type="button" v-if="deploymentStep == 2">
                                <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                                Fetching contract code...
                            </button>
                            <button disabled class="btn btn-primary w-100 disabled" type="button" v-if="deploymentStep == 3">
                                <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                                Submitting deployment transaction...
                            </button>
                            <button disabled class="btn btn-primary w-100 disabled" type="button" v-if="deploymentStep == 4">
                                <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                                Waiting on transaction confirmation...
                            </button>
                            <p v-if="deploymentStep == 4">Click <a v-bind:href="token.deployment.tx" target="_blank">here</a> to see the transaction on Etherscan.</p>
                            <button disabled class="btn btn-primary w-100 disabled" type="button" v-if="deploymentStep == 5">
                                <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                                Submitting configuration transaction...
                            </button>
                            <button disabled class="btn btn-primary w-100 disabled" type="button" v-if="deploymentStep == 6">
                                <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                                Waiting on transaction confirmation...
                            </button>
                            <p v-if="deploymentStep == 6">Click <a v-bind:href="token.deployment.tx" target="_blank">here</a> to see the transaction on Etherscan.</p>
                            <button disabled class="btn btn-primary w-100 disabled" type="button" v-if="deploymentStep == 7">
                                <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                                Verifying contract...
                            </button>

                            <button disabled class="btn btn-primary w-100 disabled" type="button" v-if="deploymentStep == 8">
                                Deployed!
                            </button>
                            <p v-if="deploymentStep == 8">Click <a v-bind:href="token.deployment.contract" target="_blank">here</a> to see the contract on Etherscan!</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>
