import AppKit

// The status-bar UI. Reflects Core's state and drives it from clicks.
final class MenuBar: NSObject {
    private var item: NSStatusItem!

    func install() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        Core.shared.onChange = { [weak self] in self?.render() }
        render()
    }

    private func render() {
        let s = Core.shared.status()
        if let button = item.button {
            let symbol = s.active ? "moon.fill" : "moon"
            let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "nocturne")
            image?.isTemplate = true
            button.image = image
            button.title = ""
        }

        let menu = NSMenu()
        if s.active {
            menu.addItem(withTitle: s.message, action: nil, keyEquivalent: "")
            menu.addItem(.separator())
            add(menu, "Turn Off", #selector(off))
        } else {
            menu.addItem(withTitle: "Nocturne — off", action: nil, keyEquivalent: "")
            menu.addItem(.separator())
            addOn(menu, "Indefinitely", nil)
            addOn(menu, "For 30 minutes", 1800)
            addOn(menu, "For 1 hour", 3600)
            addOn(menu, "For 2 hours", 7200)
        }
        menu.addItem(.separator())
        add(menu, "Quit", #selector(quit))
        item.menu = menu
    }

    private func add(_ menu: NSMenu, _ title: String, _ action: Selector) {
        let mi = NSMenuItem(title: title, action: action, keyEquivalent: "")
        mi.target = self
        menu.addItem(mi)
    }

    private func addOn(_ menu: NSMenu, _ title: String, _ seconds: Int?) {
        let mi = NSMenuItem(title: title, action: #selector(on(_:)), keyEquivalent: "")
        mi.target = self
        mi.representedObject = seconds
        menu.addItem(mi)
    }

    @objc private func on(_ sender: NSMenuItem) {
        Core.shared.turnOn(seconds: sender.representedObject as? Int, mode: .full)
    }
    @objc private func off() { Core.shared.turnOff() }
    @objc private func quit() { Core.shared.turnOff(); NSApp.terminate(nil) }
}
