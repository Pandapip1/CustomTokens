<script setup lang="ts">
import { ref } from "vue";
import Web3Modal from "web3modal";
import ethers from "ethers";
import ethProvider from "eth-provider";
import WalletConnectProvider from "@walletconnect/web3-provider"
import "bootstrap";


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
    }
});
const deploymentStep = ref(0);


async function deploy(event : MouseEvent) : Promise<void> {
    // Login
    this.deploymentStep = 1;
    const providerOptions = {
        walletconnect: {
            package: WalletConnectProvider,
            options: {
                infuraId: "" // TODO
            }
        },
        frame: {
            package: ethProvider
        }
    };

    const web3Modal = new Web3Modal({
        network: "xdai", // Gnosis Chain
        cacheProvider: true,
        providerOptions
    });

    const instance = await web3Modal.connect();

    const provider = new ethers.providers.Web3Provider(instance);
    const signer = provider.getSigner();
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
                                    <input type="text" class="form-control" placeholder="Initial Supply" aria-label="Initial Supply" aria-describedby="isupply-addon" readonly v-bind:value="`${token.redist.fee}%`">
                                </div>
                                <div class="input-group mb-3" v-for="(item, index) in token.supply" v-bind:key="item.addr">
                                    <span class="input-group-text" v-bind:id="`redist-addon${index}`">{{ item.addr }}</span>
                                    <input type="text" class="form-control" placeholder="Redist" aria-label="Redist" v-bind:aria-describedby="`redist-addon${index}`" readonly v-bind:value="`${item.amt} ${token.meta.symbol}`">
                                </div>
                            <hr/>
                            </div>
                            <div class="progress" v-if="deploymentStep != 0">
                                <div class="progress-bar" role="progressbar" v-bind:aria-valuenow="deploymentStep" v-bind:style="{ width: `${deploymentStep * 4}%` }" aria-valuemin="0" aria-valuemax="100"></div>
                            </div>
                            <button v-on:click="deploy" class="btn btn-primary w-100" v-bind:class="{ disabled: deploymentStep != 0 }" type="button" v-bind:disabled="deploymentStep != 0">
                                <span v-if="deploymentStep != 0 && deploymentStep != 2" class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                                <span v-if="deploymentStep != 0 && deploymentStep != 2">Deploying...</span>
                                <span v-if="deploymentStep == 2">Deployed!</span>
                                <span v-if="deploymentStep == 0">Deploy</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>
