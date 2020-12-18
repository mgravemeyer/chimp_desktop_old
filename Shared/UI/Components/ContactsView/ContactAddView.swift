import SwiftUI

struct ContactAddView: View {
    
    @EnvironmentObject var contactsState: ContactsState
    @EnvironmentObject var authState: AuthState
    
    @FetchRequest(sortDescriptors: [])
    private var contactsDetail: FetchedResults<ContactDetail>
    
    let gray = Color(red: 207/255, green: 207/255, blue: 212/255)
    let lightGray = Color(red: 240/255, green: 240/255, blue: 240/255)
    
    @State var firstName = String()
    @State var lastName = String()
    @State var email = String()
    @State var telephone = String()
    @State var birthDate = Date()
    
    @State var selected = false
    @State var hoverRow = false
        
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    HStack {
                        Spacer()
                        Button("Close") {
                            contactsState.pressAddMenue()
                        }.padding(.trailing, 20).padding(.top, 30)
                        Button {
                            for (contactD) in contactsDetail{
                                CoreDataService.shared.viewContext.delete(contactD)
                                let savedResult = CoreDataService.shared.save()
                                if savedResult != nil {
                                    print("Error appeared while saving a new contact")
                                }
                            }
                        } label: {
                            Text("delete cdata ")
                                .fontWeight(.semibold)
                                .frame(minWidth: 230)
                                .foregroundColor(Color.blue)
                        }
                    }
                    Spacer()
                    VStack {
                        HStack {
                            Text("Add").font(.system(size: 30)).fontWeight(.bold).zIndex(1)
                            Text("Contact").font(.system(size: 30)).fontWeight(.light).zIndex(1)
                        }
                        HStack {
                            ChimpTextField(placeholder: "First Name", value: self.$firstName)
                            ChimpTextField(placeholder: "Last Name", value: self.$lastName)
                        }
                        
                        ChimpTextField(placeholder: "E-Mail", value: self.$email)
                        ChimpTextField(placeholder: "Telephone", value: self.$telephone)
                        
                        ChimpDatePicker(birthDate: self.$birthDate)
                       
                        ZStack(alignment: .center) {
                            HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save").fontWeight(.bold)
                            }.zIndex(1)
                            RoundedRectangle(cornerRadius: 20).foregroundColor(selected || hoverRow ? gray : lightGray).onHover { (hover) in
                                self.hoverRow = hover
                            }
                        }.onTapGesture {
                            // TODO: save new contact function to the DB
                            self.contactsState.createContact(contact: Contact(
                                                                firstname: self.firstName,
                                                                lastname: self.lastName,
                                                                email: self.email,
                                                                telephone: self.telephone,
                                                                birthday: String(Int(self.birthDate.timeIntervalSince1970*1000)), // d.o.b in epoch in string format
                                                                company: "")
                            )
                            contactsState.pressAddMenue()
                        }
                    }.frame(maxWidth: 320, maxHeight: 320)
                    Spacer()
                }.padding(.bottom, 50).zIndex(1).frame(width: geometry.size.width, height: geometry.size.height).background(Color.white).opacity(0.97)
            }
        }
    }
}

struct ContactAddView_Previews : PreviewProvider {
    static var previews: some View {
        CoreDataService.shared.changeToDevelopmentMode()
        return VStack {
            ContactAddView()
                .frame(width: 500, height: 400)
            ContactAddView(
                firstName: "FirstNameadasaggggggggggg",
                lastName: "LastNamegggggggggggggg",
                email: "TestEmail@web.deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
                telephone: "0162435612341233423253421234123421412314113",
                birthDate: Date()
            )
                .frame(width: 500, height: 400)
        }.environmentObject(ContactsState())
    }
}


//TO:DO: PUT FUNTION INTO CLASS OR STRUCT
func createExternalContactDetailViewWindow(contact: Contact) {
    let mousePos = NSEvent.mouseLocation
    var windowRef:NSWindow
    windowRef = NSWindow(
        contentRect: NSRect(x: mousePos.x, y: mousePos.y, width: 300, height: 400),
        styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .resizable],
        backing: .buffered, defer: false)
    windowRef.contentView = NSHostingView(rootView: ExternalContactDetailView(contact: contact, myWindow: windowRef))
    windowRef.makeKeyAndOrderFront(nil)
}