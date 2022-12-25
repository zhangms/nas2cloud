import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './views/App';
import {Provider} from "react-redux";
import store from "./models";

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
    <Provider store={store}>
        <React.StrictMode>
            <App/>
        </React.StrictMode>
    </Provider>
);