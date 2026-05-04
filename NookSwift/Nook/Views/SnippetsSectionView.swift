import SwiftUI
import AppKit

struct SnippetsSectionView: View {
    @ObservedObject var store: Store
    @State private var isCollapsed = true
    @State private var isAdding = false
    @State private var editingId: Int?
    @State private var inputValue = ""
    @State private var toastMessage: String?
    @State private var toastDismiss: DispatchWorkItem?
    @State private var hoveredSnippetId: Int?

    @Environment(\.colorScheme) private var colorScheme

    private var rowHover: Color {
        NookTheme.bgHover(colorScheme)
    }
    private var buttonHoverBg: Color {
        NookTheme.bg2(colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if !isCollapsed {
                snippetsList
                if isAdding || editingId != nil {
                    addForm
                }
            }
        }
        .background(Color.clear)
        .overlay(alignment: .bottom) {
            if let msg = toastMessage {
                Text(msg)
                    .font(.nook(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 4)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            NookIcon(.chevron, size: 10)
                .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                .foregroundStyle(NookTheme.t4(colorScheme))
            NookIcon(.clip, size: 13)
                .foregroundStyle(NookTheme.t4(colorScheme))
            Text("Snippets")
                .font(.nook(size: 11, weight: .semibold))
                .foregroundStyle(NookTheme.t3(colorScheme))
            if !store.snippets.isEmpty {
                Text("\(store.snippets.count)")
                    .font(.nook(size: 11))
                    .foregroundStyle(NookTheme.t4(colorScheme))
            }
            Spacer()
            Button {
                isCollapsed = false
                isAdding = true
                editingId = nil
                inputValue = ""
            } label: {
                NookIcon(.plus, size: 14)
                    .foregroundStyle(NookTheme.t4(colorScheme))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) { isCollapsed.toggle() }
        }
    }

    private var snippetsList: some View {
        VStack(spacing: 1) {
            if store.snippets.isEmpty {
                Text("Click + to save text you copy often")
                    .font(.nook(size: 11))
                    .foregroundStyle(NookTheme.t4(colorScheme).opacity(0.5))
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(store.snippets.enumerated()), id: \.element.id) { idx, snippet in
                    snippetRow(snippet, index: idx + 1)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 8)
    }

    private func snippetRow(_ snippet: Snippet, index: Int) -> some View {
        let isHovered = hoveredSnippetId == snippet.id
        return HStack(spacing: 8) {
            Text("\(index)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(NookTheme.t4(colorScheme))
                .frame(width: 12, alignment: .trailing)
            Text(snippet.value.isEmpty ? "(empty)" : snippet.value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(NookTheme.t2(colorScheme))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            // Buttons always occupy layout space — only opacity/hit-testing toggles on hover.
            // Otherwise the row jumps from ~14pt to 20pt high when hovered, making the list shift.
            HStack(spacing: 0) {
                Button {
                    copyToClipboard(snippet)
                } label: {
                    NookIcon(.copy, size: 10)
                        .foregroundStyle(NookTheme.t4(colorScheme))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button {
                    editingId = snippet.id
                    isAdding = false
                    inputValue = snippet.value
                } label: {
                    NookIcon(.pen, size: 10)
                        .foregroundStyle(NookTheme.t4(colorScheme))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.deleteSnippet(snippet.id)
                    }
                } label: {
                    NookIcon(.trash, size: 10)
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
            .opacity(isHovered ? 1 : 0)
            .allowsHitTesting(isHovered)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(minHeight: 30)
        .background(isHovered ? rowHover : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onHover { hovering in hoveredSnippetId = hovering ? snippet.id : nil }
        .onTapGesture { copyToClipboard(snippet) }
    }

    private var addForm: some View {
        VStack(spacing: 4) {
            TextField("Paste or type, then Enter to save", text: $inputValue)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(NookTheme.t2(colorScheme))
                .padding(8)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                .onSubmit { saveSnippet() }
                .onExitCommand { cancelForm() }

            HStack {
                Spacer()
                Button("Cancel") { cancelForm() }
                    .font(.nook(size: 11))
                    .foregroundStyle(NookTheme.t4(colorScheme))
                    .buttonStyle(.plain)
                Button("Save") { saveSnippet() }
                    .font(.nook(size: 11, weight: .medium))
                    .foregroundStyle(NookTheme.tagOnFg(colorScheme))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(NookTheme.accent(colorScheme), in: RoundedRectangle(cornerRadius: 5))
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func saveSnippet() {
        let value = inputValue
        guard !value.isEmpty else { return }
        if let id = editingId {
            store.updateSnippet(id, value: value)
        } else {
            store.addSnippet(label: "", value: value)
        }
        cancelForm()
    }

    private func cancelForm() {
        isAdding = false
        editingId = nil
        inputValue = ""
    }

    private func copyToClipboard(_ snippet: Snippet) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.value, forType: .string)
        withAnimation(.easeInOut(duration: 0.2)) { toastMessage = "Copied" }
        // Cancel any pending dismiss from a previous copy — otherwise rapid clicks
        // cause the older timer to clear the new toast prematurely.
        toastDismiss?.cancel()
        let item = DispatchWorkItem {
            withAnimation { toastMessage = nil }
        }
        toastDismiss = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: item)
    }
}
