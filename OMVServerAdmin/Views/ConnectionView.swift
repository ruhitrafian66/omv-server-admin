import SwiftUI

struct ConnectionView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @State private var ip = ""
    @State private var port = "80"
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Details")) {
                    TextField("IP Address", text: $ip)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.decimalPad)
                    
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Credentials")) {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                
                if let error = connectionManager.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: connect) {
                        if connectionManager.isConnecting {
                            HStack {
                                Spacer()
                                ProgressView()
                                Text("Connecting...")
                                    .padding(.leading, 8)
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Connect")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .disabled(ip.isEmpty || username.isEmpty || password.isEmpty || connectionManager.isConnecting)
                }
            }
            .navigationTitle("Connect to Server")
        }
    }
    
    private func connect() {
        Task {
            await connectionManager.connect(ip: ip, port: port, username: username, password: password)
        }
    }
}
