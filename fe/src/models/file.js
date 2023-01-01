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
        currentPath: "/",
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
                currentPath: ret.currentPath
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
                data: data,
                moreLoading: false
            }
        },

        onLoaded: function (state, action) {
            return {
                ...state,
                initLoading: false,
                moreLoading: false,
                data: action.payload
            }
        }
    }
})

export const FileReducer = fileSlice.reducer
export const FileActions = fileSlice.actions