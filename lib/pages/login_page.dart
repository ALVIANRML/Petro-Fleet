import 'package:flutter/material.dart';
import 'main_dashboard_page.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/img/bg_login.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/img/petrofleet.png', width: 400),
                SizedBox(height: 26),
                TextField(
                  controller: _usernameController,

                  style: TextStyle(color: Colors.white,),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white70,),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54)
                    ),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(
                      color: Colors.blue,     // border saat fokus
                      width: 2,
                    ),
                    ),

                  ),
                ),
                SizedBox(height: 26),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  style: TextStyle(color: Colors.white,),
                  decoration: InputDecoration(
                      labelStyle: TextStyle(color: Colors.white70,),
                      labelText: 'Passowrd',
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 2)),
                      suffixIcon: IconButton(icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white70,
                      ), onPressed: (){
                        setState(() {
                          _obscure = !_obscure;
                        });
                      })
                  ),
                ),
                SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: ElevatedButton(
                    onPressed: () {
                      final user = _usernameController.text;
                      final pass = _passwordController.text;

                      if (user == 'admin' && pass == '123') {
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.success,
                        animType: AnimType.scale,
                        title: 'Berhasil',
                        desc:'Login Berhasil',
                        btnOkOnPress: (){
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()),
                          );
                        },
                      ).show();
                      } else{
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Username atau Password Salah! Silahkan Coba Lagi'),
                          backgroundColor: Colors.red,),);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B62FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 26),
                Center(
                  child: Text(
                    'Forgot Password?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}