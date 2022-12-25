import React from 'react';
import Login from "./login/Login";
import {connect} from "react-redux";

class App extends React.Component {

    render() {
        const {loginState} = this.props
        return (
            loginState ? <>login success</> : <Login/>
        )
    }
}

export default App = connect(function (state) {
    return {...state.App}
})(App);
