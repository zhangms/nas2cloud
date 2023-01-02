import {createSlice} from "@reduxjs/toolkit";

const stateKey = "_file_current_state_"

function saveCurrentState(state) {
    localStorage.setItem(stateKey, JSON.stringify(state))
}

function loadInitState() {
    const defaultState = {
        initLoading: true,
        moreLoading: false,
        orderBy: "fileName_asc",
        createFolder: false,
        path: "/",
        data: {
            files: [],
            nav: [],
            total: 0,
            currentIndex: 0,
            currentPage: 0,
        }
    }
    const value = localStorage.getItem(stateKey)
    if (value == null) {
        return defaultState
    }
    const state = JSON.parse(value)
    return {...defaultState, ...state}
}

const fileSlice = createSlice({
    name: "fileSlice",
    initialState: loadInitState(),
    reducers: {
        changeState: function (state, action) {
            const ret = {...state, ...action.payload}
            saveCurrentState({
                orderBy: ret.orderBy,
                path: ret.path
            })
            return ret
        },

        onLoadMore: function (state, action) {
            let files = [...state.data.files]
            files.push(...action.payload.files)
            let data = {
                ...state.data,
                ...action.payload,
                files: files
            }
            return {
                ...state,
                moreLoading: false,
                data: data,
            }
        },

        onLoaded: function (state, action) {
            return {
                ...state,
                initLoading: false,
                moreLoading: false,
                createFolder: false,
                data: action.payload
            }
        },

        onDelete: function (state, action) {
            const item = action.payload;
            let files = [...state.data.files];
            for (let i = 0; i < files.length; i++) {
                const f = files[i];
                if (f.path === item.path) {
                    files.splice(i, 1)
                    break;
                }
            }
            let data = {
                ...state.data,
                files: files,
                total: state.data.total - 1
            }
            return {
                ...state,
                initLoading: false,
                moreLoading: false,
                createFolder: false,
                data: data
            }
        }
    }
})

export const FileReducer = fileSlice.reducer
export const FileActions = fileSlice.actions