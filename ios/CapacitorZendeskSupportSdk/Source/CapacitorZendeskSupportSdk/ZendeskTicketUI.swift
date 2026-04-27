import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import SafariServices
import SupportSDK
import SupportProvidersSDK
import CommonUISDK

// MARK: - Ticket List

struct TicketListView: View {
    let primaryColor: Color
    let onDismiss: () -> Void

    @SwiftUI.State private var tickets: [SupportProvidersSDK.ZDKRequest] = []
    @SwiftUI.State private var requestUpdates: RequestUpdates? = nil
    @SwiftUI.State private var isLoading = true
    @SwiftUI.State private var errorMessage: String? = nil
    @SwiftUI.State private var selectedTicket: SupportProvidersSDK.ZDKRequest? = nil

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else if tickets.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No requests")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    List(tickets, id: \.requestId) { ticket in
                        Button(action: {
                            markAsRead(ticket)
                            selectedTicket = ticket
                        }) {
                            TicketRow(
                                ticket: ticket,
                                primaryColor: primaryColor,
                                hasUnread: hasUnread(ticket)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("My Requests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close", action: onDismiss)
                        .foregroundColor(primaryColor)
                }
            }
        }
        .sheet(item: $selectedTicket) { ticket in
            TicketDetailContainerView(ticket: ticket, primaryColor: primaryColor)
        }
        .onAppear(perform: loadTickets)
    }

    private func hasUnread(_ ticket: ZDKRequest) -> Bool {
        guard let updates = requestUpdates else { return false }
        return updates.isRequestUnread(ticket.requestId)
    }


    private func markAsRead(_ ticket: ZDKRequest) {
        let count = ticket.commentCount.intValue
        SupportSDK.ZDKRequestProvider().markRequestAsRead(ticket.requestId, withCommentCount: count)
    }

    private func loadTickets() {
        let group = DispatchGroup()
        var fetchedTickets: [ZDKRequest] = []
        var fetchedUpdates: RequestUpdates?

        group.enter()
        SupportSDK.ZDKRequestProvider().getAllRequests { result, _ in
            if let result = result as? SupportProvidersSDK.ZDKRequestsWithCommentingAgents {
                fetchedTickets = result.requests
            }
            group.leave()
        }

        group.enter()
        SupportSDK.ZDKRequestProvider().getUpdatesForDevice { updates in
            fetchedUpdates = updates
            group.leave()
        }

        group.notify(queue: .main) {
            isLoading = false
            if fetchedTickets.isEmpty && fetchedUpdates == nil {
                errorMessage = "Could not load requests"
            } else {
                tickets = fetchedTickets
                requestUpdates = fetchedUpdates
            }
        }
    }
}

struct TicketRow: View {
    let ticket: SupportProvidersSDK.ZDKRequest
    let primaryColor: Color
    let hasUnread: Bool

    private var title: String {
        // If no agent reply yet, use the subject as title
        if let subject = ticket.subject, !subject.isEmpty {
            let hasAgentReply = ticket.commentCount.intValue > 1
            if !hasAgentReply {
                return subject
            }
        }
        return ticket.subject ?? ticket.requestDescription ?? "Support request"
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yy HH:mm"
        return f.string(from: ticket.updateAt)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Unread indicator dot
            Circle()
                .fill(hasUnread ? primaryColor : Color.clear)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(title)
                        .font(.body)
                        .fontWeight(hasUnread ? .semibold : .regular)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
                if let last = ticket.lastComment, let body = last.body, !body.isEmpty {
                    Text(body)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                StatusBadge(status: ticket.status ?? "open", primaryColor: primaryColor)
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatusBadge: View {
    let status: String
    let primaryColor: Color

    private var color: Color {
        switch status.lowercased() {
        case "new", "open": return primaryColor
        case "pending": return .orange
        default: return Color(.systemGray)
        }
    }

    var body: some View {
        Text(status.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

// MARK: - Ticket Detail

struct TicketDetailContainerView: View {
    let ticket: SupportProvidersSDK.ZDKRequest
    let primaryColor: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TicketDetailView(ticket: ticket, primaryColor: primaryColor, onDismiss: { dismiss() })
    }
}

struct TicketDetailView: View {
    let ticket: SupportProvidersSDK.ZDKRequest
    let primaryColor: Color
    let onDismiss: () -> Void

    @SwiftUI.State private var comments: [SupportProvidersSDK.ZDKCommentWithUser] = []
    @SwiftUI.State private var isLoading = true
    @SwiftUI.State private var replyText = ""
    @SwiftUI.State private var isSending = false
    @SwiftUI.State private var errorMessage: String? = nil
    @SwiftUI.State private var pendingAttachments: [PendingAttachment] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(comments.indices, id: \.self) { i in
                                    CommentRow(
                                        comment: comments[i].comment,
                                        user: comments[i].user,
                                        isEndUser: !(comments[i].user?.isAgent ?? false),
                                        primaryColor: primaryColor
                                    )
                                    .id(i)
                                    if i < comments.count - 1 {
                                        Divider().padding(.leading, 56)
                                    }
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .onChange(of: comments.count) {
                            proxy.scrollTo(comments.count - 1, anchor: .bottom)
                        }
                    }
                }

                Divider()
                ReplyBar(
                    text: $replyText,
                    pendingAttachments: $pendingAttachments,
                    isSending: isSending,
                    primaryColor: primaryColor,
                    onSend: sendReply
                )
            }
            .navigationTitle(ticket.subject ?? "Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back", action: onDismiss)
                        .foregroundColor(primaryColor)
                }
            }
        }
        .onAppear(perform: loadComments)
    }

    private func loadComments() {
        SupportSDK.ZDKRequestProvider().getCommentsWithRequestId(ticket.requestId) { result, error in
            DispatchQueue.main.async {
                isLoading = false
                if let result = result as? [SupportProvidersSDK.ZDKCommentWithUser] {
                    comments = result.reversed()
                } else {
                    errorMessage = "Could not load comments"
                }
            }
        }
    }

    private func sendReply() {
        let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || !pendingAttachments.isEmpty else { return }
        isSending = true

        uploadAttachments(pendingAttachments) { responses in
            SupportSDK.ZDKRequestProvider().addComment(
                text.isEmpty ? " " : text,
                forRequestId: ticket.requestId,
                attachments: responses
            ) { _, error in
                DispatchQueue.main.async {
                    isSending = false
                    if error == nil {
                        replyText = ""
                        pendingAttachments = []
                        loadComments()
                    }
                }
            }
        }
    }

    private func uploadAttachments(_ attachments: [PendingAttachment], completion: @escaping ([SupportProvidersSDK.ZDKUploadResponse]) -> Void) {
        guard !attachments.isEmpty else { completion([]); return }
        var responses: [SupportProvidersSDK.ZDKUploadResponse] = []
        let group = DispatchGroup()

        for attachment in attachments {
            group.enter()
            SupportSDK.ZDKUploadProvider().uploadAttachment(
                attachment.data,
                withFilename: attachment.filename,
                andContentType: attachment.mimeType
            ) { result, _ in
                if let response = result as? SupportProvidersSDK.ZDKUploadResponse {
                    responses.append(response)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { completion(responses) }
    }
}

// MARK: - Attachment model

struct PendingAttachment: Identifiable {
    let id = UUID()
    let filename: String
    let mimeType: String
    let data: Data
    let thumbnail: Image?
}

// MARK: - Comment row

struct CommentRow: View {
    let comment: SupportProvidersSDK.ZDKComment?
    let user: SupportProvidersSDK.ZDKSupportUser?
    let isEndUser: Bool
    let primaryColor: Color

    private var initials: String {
        let name = user?.name ?? ""
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var formattedDate: String {
        guard let date = comment?.createdAt else { return "" }
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yy HH:mm"
        return f.string(from: date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isEndUser ? primaryColor.opacity(0.15) : Color(.systemGray5))
                    .frame(width: 36, height: 36)
                Text(initials)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isEndUser ? primaryColor : Color(.systemGray))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(user?.name ?? (isEndUser ? "You" : "Agent"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
                if let body = comment?.body, !body.isEmpty {
                    Text(body)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let attachments = comment?.attachments as? [SupportProvidersSDK.ZDKAttachment], !attachments.isEmpty {
                    AttachmentRow(attachments: attachments)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isEndUser ? primaryColor.opacity(0.04) : Color(.systemBackground))
    }
}

// MARK: - Attachment display in comments

struct AttachmentRow: View {
    let attachments: [SupportProvidersSDK.ZDKAttachment]
    @SwiftUI.State private var safariURL: URL? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(attachments, id: \.contentURLString) { attachment in
                Button(action: { open(attachment) }) {
                    HStack(spacing: 6) {
                        Image(systemName: iconForMime(attachment.contentType ?? ""))
                            .font(.system(size: 13))
                            .foregroundColor(.accentColor)
                        Text(attachment.filename ?? "Attachment")
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
        }
    }

    private func open(_ attachment: ZDKAttachment) {
        guard let urlString = attachment.contentURLString,
              let url = URL(string: urlString) else { return }
        safariURL = url
    }

    private func iconForMime(_ mime: String) -> String {
        if mime.hasPrefix("image/") { return "photo" }
        if mime.hasPrefix("video/") { return "video" }
        if mime.contains("pdf") { return "doc.richtext" }
        return "paperclip"
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Reply bar

struct ReplyBar: View {
    @Binding var text: String
    @Binding var pendingAttachments: [PendingAttachment]
    let isSending: Bool
    let primaryColor: Color
    let onSend: () -> Void

    @SwiftUI.State private var showPhotoPicker = false
    @SwiftUI.State private var showCamera = false
    @SwiftUI.State private var showFilePicker = false
    @SwiftUI.State private var photoPickerItem: PhotosPickerItem? = nil

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !pendingAttachments.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if !pendingAttachments.isEmpty {
                AttachmentPreviewStrip(attachments: $pendingAttachments)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }

            HStack(alignment: .bottom, spacing: 8) {
                // Paperclip with native iOS context menu
                Menu {
                    Button(action: { showPhotoPicker = true }) {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
                    }
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button(action: { showCamera = true }) {
                            Label("Camera", systemImage: "camera")
                        }
                    }
                    Button(action: { showFilePicker = true }) {
                        Label("File", systemImage: "doc")
                    }
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 16, weight: .light))
                        .rotationEffect(.degrees(30))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                }

                TextField("Add a reply…", text: $text, axis: .vertical)
                    .font(.body)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Button(action: onSend) {
                    if isSending {
                        ProgressView().tint(.white)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 32, height: 32)
                .background(canSend && !isSending ? primaryColor : Color(.systemGray3))
                .clipShape(Circle())
                .disabled(!canSend || isSending)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .any(of: [.images, .videos]))
        .onChange(of: photoPickerItem) {
            guard let item = photoPickerItem else { return }
            loadPhotoPickerItem(item)
            photoPickerItem = nil
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView { image in
                guard let data = image.jpegData(compressionQuality: 0.8) else { return }
                let filename = "photo_\(Int(Date().timeIntervalSince1970)).jpg"
                pendingAttachments.append(PendingAttachment(filename: filename, mimeType: "image/jpeg", data: data, thumbnail: Image(uiImage: image)))
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePickerView { url in
                guard let data = try? Data(contentsOf: url) else { return }
                let mime = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
                pendingAttachments.append(PendingAttachment(filename: url.lastPathComponent, mimeType: mime, data: data, thumbnail: nil))
            }
        }
        .background(Color(.systemBackground))
    }

    private func loadPhotoPickerItem(_ item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                guard let data = try? result.get() else { return }
                let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .audiovisualContent) })
                let mime = isVideo ? "video/mp4" : "image/jpeg"
                let ext = isVideo ? "mp4" : "jpg"
                let filename = "attachment_\(Int(Date().timeIntervalSince1970)).\(ext)"
                let thumbnail: Image? = isVideo ? Image(systemName: "video") : {
                    guard let ui = UIImage(data: data) else { return nil }
                    return Image(uiImage: ui)
                }()
                pendingAttachments.append(PendingAttachment(filename: filename, mimeType: mime, data: data, thumbnail: thumbnail))
            }
        }
    }
}

// MARK: - Camera picker

struct CameraPickerView: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage) -> Void
        init(onImage: @escaping (UIImage) -> Void) { self.onImage = onImage }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage { onImage(image) }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - File picker

struct FilePickerView: UIViewControllerRepresentable {
    let onFile: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFile: onFile) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFile: (URL) -> Void
        init(onFile: @escaping (URL) -> Void) { self.onFile = onFile }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            onFile(url)
        }
    }
}

// MARK: - Attachment preview strip

struct AttachmentPreviewStrip: View {
    @Binding var attachments: [PendingAttachment]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { attachment in
                    ZStack(alignment: .topTrailing) {
                        Group {
                            if let thumb = attachment.thumbnail {
                                thumb
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color(.systemGray5)
                                    .overlay(Image(systemName: "paperclip").foregroundColor(.secondary))
                            }
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button(action: { attachments.removeAll { $0.id == attachment.id } }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.4).clipShape(Circle()))
                        }
                        .offset(x: 4, y: -4)
                    }
                }
            }
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Identifiable conformance for .sheet(item:)

extension SupportProvidersSDK.ZDKRequest: @retroactive Identifiable {
    public var id: String { requestId }
}
